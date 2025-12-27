#!/usr/bin/env python3
"""
Delete CloudFormation stack and all retained resources.

This script:
1. Downloads the current stack template
2. Changes all DeletionPolicy to Delete
3. Updates the stack with the modified template
4. Finds and empties all S3 buckets in the stack
5. Deletes the stack

Usage:
    python delete-stack-and-all-retained-resources.py \
        --profile my-profile \
        --region us-west-2 \
        --stack-name MyStack
"""

import argparse
import boto3
import json
import sys
import yaml


def main():
    parser = argparse.ArgumentParser(
        description='Delete CloudFormation stack and all retained resources'
    )
    parser.add_argument('--profile', required=True, help='AWS profile name')
    parser.add_argument('--region', required=True, help='AWS region')
    parser.add_argument('--stack-name', required=True, help='CloudFormation stack name')
    args = parser.parse_args()

    # Create boto3 session with profile
    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    cfn = session.client('cloudformation')
    s3 = session.client('s3')

    print(f"Processing stack: {args.stack_name}")

    # Step 1: Get the current template
    print("\n[1/5] Downloading current template...")
    try:
        response = cfn.get_template(StackName=args.stack_name, TemplateStage='Original')
        template_body = response['TemplateBody']

        # Template might be returned as string (YAML/JSON) or dict
        if isinstance(template_body, str):
            # Try parsing as JSON first, then YAML
            try:
                template = json.loads(template_body)
            except json.JSONDecodeError:
                template = yaml.safe_load(template_body)
        else:
            template = template_body
    except cfn.exceptions.ClientError as e:
        print(f"Error: Stack '{args.stack_name}' not found or inaccessible: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error getting template: {e}")
        sys.exit(1)

    # Step 2: Modify all DeletionPolicy to Delete
    print("\n[2/5] Modifying DeletionPolicy to Delete for all resources...")
    modified = False
    if 'Resources' in template:
        for resource_name, resource in template['Resources'].items():
            changed = False
            if resource.get('DeletionPolicy') != 'Delete':
                resource['DeletionPolicy'] = 'Delete'
                changed = True
            if resource.get('UpdateReplacePolicy') != 'Delete':
                resource['UpdateReplacePolicy'] = 'Delete'
                changed = True

            if changed:
                modified = True
                print(f"  ✓ {resource_name}: Set DeletionPolicy and UpdateReplacePolicy to Delete")

    if not modified:
        print("  No resources needed DeletionPolicy changes")

    # Step 3: Update the stack with modified template
    print("\n[3/5] Updating stack with modified template...")
    print("  Retaining all existing stack parameters")
    try:
        # Note: By omitting the Parameters key, CloudFormation automatically
        # uses all previous parameter values
        cfn.update_stack(
            StackName=args.stack_name,
            TemplateBody=json.dumps(template),
            Capabilities=['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM', 'CAPABILITY_AUTO_EXPAND']
        )

        # Wait for update to complete
        print("  Waiting for stack update to complete...")
        waiter = cfn.get_waiter('stack_update_complete')
        waiter.wait(StackName=args.stack_name)
        print("  ✓ Stack update complete")
    except cfn.exceptions.ClientError as e:
        if 'No updates are to be performed' in str(e):
            print("  ✓ No updates needed (already configured correctly)")
        else:
            print(f"  ⚠ Error updating stack: {e}")
            print("  Continuing anyway - might still need to empty buckets")

    # Step 4: Find and empty S3 buckets
    print("\n[4/5] Finding and emptying S3 buckets in stack...")
    try:
        resources = cfn.list_stack_resources(StackName=args.stack_name)
        buckets = []

        for resource in resources['StackResourceSummaries']:
            if resource['ResourceType'] == 'AWS::S3::Bucket':
                bucket_name = resource['PhysicalResourceId']
                buckets.append(bucket_name)
                print(f"  Found bucket: {bucket_name}")

        if not buckets:
            print("  No S3 buckets found in stack")

        # Empty each bucket
        for bucket_name in buckets:
            print(f"  Emptying bucket: {bucket_name}")
            try:
                # Delete all object versions and delete markers
                paginator = s3.get_paginator('list_object_versions')
                deleted_count = 0

                for page in paginator.paginate(Bucket=bucket_name):
                    # Delete versions
                    if 'Versions' in page:
                        for version in page['Versions']:
                            s3.delete_object(
                                Bucket=bucket_name,
                                Key=version['Key'],
                                VersionId=version['VersionId']
                            )
                            deleted_count += 1

                    # Delete delete markers
                    if 'DeleteMarkers' in page:
                        for marker in page['DeleteMarkers']:
                            s3.delete_object(
                                Bucket=bucket_name,
                                Key=marker['Key'],
                                VersionId=marker['VersionId']
                            )
                            deleted_count += 1

                print(f"    ✓ Deleted {deleted_count} objects from {bucket_name}")
            except s3.exceptions.NoSuchBucket:
                print(f"    ⚠ Bucket {bucket_name} no longer exists")
            except Exception as e:
                print(f"    ✗ Error emptying bucket {bucket_name}: {e}")
                print(f"    You may need to manually empty this bucket")
    except Exception as e:
        print(f"  ⚠ Error processing buckets: {e}")
        print("  Continuing with stack deletion...")

    # Step 5: Delete the stack
    print(f"\n[5/5] Deleting stack: {args.stack_name}")
    try:
        cfn.delete_stack(StackName=args.stack_name)

        # Wait for deletion to complete
        print("  Waiting for stack deletion to complete...")
        waiter = cfn.get_waiter('stack_delete_complete')
        waiter.wait(StackName=args.stack_name)
        print(f"\n✅ Stack {args.stack_name} deleted successfully!")
    except Exception as e:
        print(f"\n✗ Error deleting stack: {e}")
        print("\nYou may need to manually delete the stack or check for remaining resources.")
        sys.exit(1)


if __name__ == '__main__':
    main()
