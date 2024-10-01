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

# Request input paths and filenames
read -p "Enter the file path to the .docx document: " docx_path
read -p "Enter the directory where the PDF should be saved (without file name): " output_folder
read -p "Enter the desired PDF file name (without extension): " pdf_name

# Ensure paths are absolute
docx_path=$(realpath "$docx_path")
output_folder=$(realpath "$output_folder")
output_pdf="$output_folder/$pdf_name.pdf"

read -p "Replace potential [Date] and [Company]? (y/n) " edit_answer

# Initialize variables
temp_docx_path=""
company_name=""
current_date=$(date +"%Y-%m-%d")

# Edit the file, if requested
if [[ "$edit_answer" == "y" || "$edit_answer" == "Y" ]]; then
	# Request company name
	read -p "Enter the company name: " company_name

	# Create a temporary copy of the .docx file
	temp_docx_path=$(mktemp --suffix=".docx")
	cp "$docx_path" "$temp_docx_path"

	# Use sed to replace [Date] and [Company] in the temporary file
	unzip -o "$temp_docx_path" -d /tmp/docx_contents
	sed -i "s/\[Date\]/$current_date/g" /tmp/docx_contents/word/document.xml
	sed -i "s/\[Company\]/$company_name/g" /tmp/docx_contents/word/document.xml
	
	cd /tmp/docx_contents 
	zip -r "$temp_docx_path" * > /dev/null
	cd -

	# Overwrite the input file path with the edited copy
	docx_path="$temp_docx_path"
fi

# Handle PDF name conflicts
output_pdf=$(handle_file_conflict "$output_pdf" "$pdf_name" "$output_folder")

# Convert the .docx file to PDF using LibreOffice
libreoffice --headless --convert-to pdf --outdir "$output_folder" "$docx_path"

# Rename the generated PDF to match the given name
input_docx_base=$(basename "$docx_path" .docx)
generated_pdf="$output_folder/$input_docx_base.pdf"

mv "$generated_pdf" "$output_pdf"

# Notify user of the operation
if [[ "$edit_answer" == "y" || "$edit_answer" == "Y" ]]; then
	echo "Replaced [Date] with $current_date and [Company] with $company_name."

	# Remove the temporary file after the PDF has been exported
	rm -f "$temp_docx_path"
fi

echo "Successfully exported the specified document as a pdf to: $output_pdf"
