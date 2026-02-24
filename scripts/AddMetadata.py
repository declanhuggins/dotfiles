import boto3
import pillow_avif
from PIL import Image
from io import BytesIO

session = boto3.session.Session(
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY
)
s3 = session.resource('s3', S3_ENDPOINT)

bucket = s3.Bucket(AWS_BUCKET_NAME)

for obj in bucket.objects.all():
    key = obj.key
    print(f"Processing: {key}")

    # Fetch the object
    response = obj.get()
    data = response['Body'].read()

    try:
        # Open image from memory and get dimensions
        image = Image.open(BytesIO(data))
        width, height = image.size
        print(f"Dimensions for {key}: {width}x{height}")
    except Exception as e:
        print(f"Skipping {key} (not a valid image): {e}")
        continue

    # Prepare new metadata
    new_metadata = {
        'width': str(width),
        'height': str(height)
    }
    # If you want to keep existing metadata, retrieve and merge it here

    # Copy the object to itself with new metadata
    copy_source = {'Bucket': bucket_name, 'Key': key}
    s3.Object(bucket_name, key).copy_from(
        CopySource=copy_source,
        Metadata=new_metadata,
        MetadataDirective='REPLACE'
    )
    print(f"Updated metadata for {key}")
