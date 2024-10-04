#!/bin/bash

# Ensure LibreOffice is installed
if ! command -v libreoffice &> /dev/null
then
	echo "You need to install LibreOffice before running this script."
	exit 1
fi

# Function to check for duplicate files and handle conflicts
handle_file_conflict() {
	local output_pdf="$1"
	local pdf_name="$2"
	local output_folder="$3"

	if [[ -f "$output_pdf" ]]; then
		read -p "PDF with the same name already exists. Do you want to overwrite it? (y/n) " answer
		if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
			rm "$output_pdf"
		else 
			date_append=$(date +"%Y-%m-%d")
			pdf_name="${pdf_name%.*}_$date_append.pdf"
			output_pdf="$output_folder/$pdf_name"
		fi
	fi

	echo "$output_pdf"
}

# Function to unzip, modify, and zip files based on file type (.docx/.odt)
modify_document() {
	local file_path="$1"
	local current_date="$2"
	local company_name="$3"
	local file_type="$4"
	local temp_file="$5"

	unzip -o "$temp_file" -d /tmp/contents
	local path_to_xml=""
	local placeholder_occurences=0

	# Set the path to the document, depending on the file type
	if [[ "$file_type" == "docx" ]]; then
		path_to_xml="tmp/contents/word/document.xml"	
	elif [[ "$file_type" == "odt" ]]; then
		path_to_xml="/tmp/contents/content.xml"
	fi

	placeholder_occurences+=$(grep -o -E "\[Date\]"\|"\[Company\]" "$path_to_xml" | wc -l)

	if [[ "$placeholder_occurences" -ne 2 ]]; then
		echo "Error: The specified file does not contain one [Date] and one [Company]."
		exit 1
	fi
	
	# Modify the document
	sed -i "s/\[Date\]/$current_date/g" "$path_to_xml"
	sed -i "s/\[Company\]/$company_name/g" "$path_to_xml"

	# Zip the contents back into the temporary file
	cd /tmp/contents
	zip -r "$temp_file" * > /dev/null
	cd -
}

# Request input paths and filenames
read -p "Enter the file path to the .docx or .odt document: " file_path

if [[ ! -f "$file_path" ]]; then
	echo "Error: The specified document does not exist."
	exit 1
fi

# Determine the file type based on the extension
file_extension="${file_path##*.}"

if [[ "$file_extension" != "docx" && "$file_extension" != "odt" ]]; then
	echo "Error: Unsupported file type. Please provide a .docx or .odt file."
	exit 1
fi

read -p "Enter the directory where the PDF should be saved (without file name): " output_folder

if [[ ! -d "$output_folder" ]]; then
	echo "Error: the specified output directory does not exist."
	exit 1
fi

# Ensure paths are absolute
file_path=$(realpath "$file_path")
output_folder=$(realpath "$output_folder")

read -p "Replace potential [Date] and [Company]? (y/n) " edit_answer

# Initialize variables
pdf_name=""
temp_file=""
company_name=""
current_date=$(date +"%Y-%m-%d")

# Edit the file, if requested
if [[ "$edit_answer" == "y" || "$edit_answer" == "Y" ]]; then
	company_name=""

	while [[ -z "$company_name" ]]
	do
		read -p "Enter the company name: " company_name
	done
	
	pdf_name="Personligt brev $company_name"

	# Create a temporary copy of the file
	temp_file=$(mktemp --suffix=".$file_extension")
	cp "$file_path" "$temp_file"

	# Modify the document
	modify_document "$file_path" "$current_date" "$company_name" "$file_extension" "$temp_file"

	# Overwrite the input file path with the edited copy
	file_path="$temp_file"
else 
	read -p "Enter the desired PDF file name (without extension): " pdf_name
fi

# Ensure path is absolute
output_pdf="$output_folder/$pdf_name.pdf"

# Handle PDF name conflicts
output_pdf=$(handle_file_conflict "$output_pdf" "$pdf_name" "$output_folder")

# Convert the .docx file to PDF using LibreOffice
libreoffice --headless --convert-to pdf --outdir "$output_folder" "$file_path"

# Rename the generated PDF to match the given name
input_file_base=$(basename "$file_path" ".$file_extension")
generated_pdf="$output_folder/$input_file_base.pdf"

if [[ -f "$generated_pdf" ]]; then
	mv "$generated_pdf" "$output_pdf"
else 
	echo "Error: PDF generation failed."
	exit 1
fi

# Notify user of the operation
if [[ "$edit_answer" == "y" || "$edit_answer" == "Y" ]]; then
	echo "Replaced [Date] with $current_date and [Company] with $company_name."

	# Remove the temporary file after the PDF has been exported
	rm -f "$temp_file"
fi

# Clean up /tmp/contents
rm -rf /tmp/contents

echo "Successfully exported the specified document as a PDF to: $output_pdf"

if command -v firefox &> /dev/null; then
	firefox "$output_pdf" &
fi
