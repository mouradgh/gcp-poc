import functions_framework
from google.cloud import storage
import xml.etree.ElementTree as ET
import json
import os
from cloudevents.http import CloudEvent

# Initialize the Cloud Storage client
storage_client = storage.Client()

def xml_to_dict(element):
    """Convert XML to dictionary recursively."""
    result = {}
    
    # Handle attributes
    for key, value in element.attrib.items():
        result[f"@{key}"] = value
    
    # Handle child elements
    for child in element:
        child_data = xml_to_dict(child)
        if child.tag in result:
            if not isinstance(result[child.tag], list):
                result[child.tag] = [result[child.tag]]
            result[child.tag].append(child_data)
        else:
            result[child.tag] = child_data
    
    # Handle text content
    if element.text and element.text.strip():
        if not result:
            result = element.text.strip()
        else:
            result["#text"] = element.text.strip()
    
    return result

@functions_framework.cloud_event
def convert_xml_to_json(cloud_event: CloudEvent) -> tuple:
    """Cloud Function triggered by Cloud Storage event"""
    try:
        # Get file information from the event
        data = cloud_event.data
        
        # Extract bucket and file information
        input_bucket_name = data["bucket"]
        input_file_name = data["name"]
        
        # Only process XML files
        if not input_file_name.lower().endswith('.xml'):
            print(f"Skipping non-XML file: {input_file_name}")
            return 'Not an XML file', 200
            
        # Set output location
        output_bucket_name = "gigawatt-processed-data"
        output_file_name = f"{os.path.splitext(input_file_name)[0]}.json"
        
        # Get the input file from GCS
        input_bucket = storage_client.bucket(input_bucket_name)
        input_blob = input_bucket.blob(input_file_name)
        
        # Download to temporary file
        temp_input_path = '/tmp/input.xml'
        input_blob.download_to_filename(temp_input_path)
        
        # Parse XML and convert to dictionary
        tree = ET.parse(temp_input_path)
        root = tree.getroot()
        xml_dict = xml_to_dict(root)
        
        # Convert to JSON
        json_data = json.dumps(xml_dict, indent=2)
        
        # Upload JSON to output bucket
        output_bucket = storage_client.bucket(output_bucket_name)
        output_blob = output_bucket.blob(output_file_name)
        output_blob.upload_from_string(json_data, content_type='application/json')
        
        # Clean up temporary files
        os.remove(temp_input_path)
        
        print(f"Successfully converted {input_file_name} to JSON")
        return 'Success', 200
        
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        return f'Error: {str(e)}', 500