require 'rails_helper'

RSpec.describe PdfSigner::EmbedSignature do
  describe '.call' do
    let(:document) { create(:document) }
    let(:signature_payload) do
      {
        image: Base64.encode64(File.read(Rails.root.join('spec/fixtures/files/sample_signature.png'))),
        page: 0,
        x: 100,
        y: 100,
        width: 100,
        height: 50
      }
    end

    before do
      # Create a sample signature image if it doesn't exist
      unless File.exist?(Rails.root.join('spec/fixtures/files/sample_signature.png'))
        require 'chunky_png'
        image = ChunkyPNG::Image.new(100, 50, ChunkyPNG::Color::WHITE)
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        image.save(Rails.root.join('spec/fixtures/files/sample_signature.png'))
      end
    end

    context 'with valid document and signature' do
      it 'returns a PDF with embedded signature' do
        result = described_class.call(
          document: document,
          signature: signature_payload
        )

        expect(result).to start_with("%PDF")
      end

      it 'returns binary content' do
        result = described_class.call(
          document: document,
          signature: signature_payload
        )

        expect(result).to be_a(String)
        expect(result.encoding).to eq(Encoding::ASCII_8BIT)
      end

      it 'can be parsed as a valid PDF' do
        result = described_class.call(
          document: document,
          signature: signature_payload
        )

        # Write to temp file since HexaPDF needs a path
        temp_file = Tempfile.new(["output", ".pdf"])
        temp_file.binmode
        temp_file.write(result)
        temp_file.rewind
        
        expect { HexaPDF::Document.open(temp_file.path) }.not_to raise_error
        temp_file.close!
      end
    end

    context 'with multiple pages' do
      let(:multi_page_document) do
        create(:document).tap do |doc|
          # Create a PDF with 3 pages
          pdf = HexaPDF::Document.new
          3.times { pdf.pages.add }
          
          pdf_io = StringIO.new
          pdf.write(pdf_io)
          pdf_io.rewind
          
          doc.file.attach(
            io: pdf_io,
            filename: "multi_page.pdf",
            content_type: "application/pdf"
          )
        end
      end

      it 'embeds signature on first page' do
        result = described_class.call(
          document: multi_page_document,
          signature: signature_payload.merge(page: 0)
        )

        expect(result).to start_with("%PDF")
        temp_file = Tempfile.new(["output", ".pdf"])
        temp_file.binmode
        temp_file.write(result)
        temp_file.rewind
        pdf = HexaPDF::Document.open(temp_file.path)
        expect(pdf.pages.length).to eq(3)
        temp_file.close!
      end

      it 'embeds signature on middle page' do
        result = described_class.call(
          document: multi_page_document,
          signature: signature_payload.merge(page: 1)
        )

        expect(result).to start_with("%PDF")
        temp_file = Tempfile.new(["output", ".pdf"])
        temp_file.binmode
        temp_file.write(result)
        temp_file.rewind
        pdf = HexaPDF::Document.open(temp_file.path)
        expect(pdf.pages.length).to eq(3)
        temp_file.close!
      end

      it 'embeds signature on last page' do
        result = described_class.call(
          document: multi_page_document,
          signature: signature_payload.merge(page: 2)
        )

        expect(result).to start_with("%PDF")
        temp_file = Tempfile.new(["output", ".pdf"])
        temp_file.binmode
        temp_file.write(result)
        temp_file.rewind
        pdf = HexaPDF::Document.open(temp_file.path)
        expect(pdf.pages.length).to eq(3)
        temp_file.close!
      end
    end

    context 'edge cases' do
      it 'handles zero coordinates' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(x: 0, y: 0)
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles string coordinates (type coercion)' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(x: "50", y: "75", width: "80", height: "40")
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles large signature dimensions' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(width: 500, height: 300)
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles small signature dimensions' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(width: 10, height: 5)
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles floating point coordinates' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(x: 100.5, y: 200.75, width: 99.9, height: 49.5)
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles string page number (type coercion)' do
        result = described_class.call(
          document: document,
          signature: signature_payload.merge(page: "0")
        )

        expect(result).to start_with("%PDF")
      end
    end

    context 'with different signature image formats' do
      it 'handles PNG signature' do
        result = described_class.call(
          document: document,
          signature: signature_payload
        )

        expect(result).to start_with("%PDF")
      end

      it 'handles small signature image' do
        require 'chunky_png'
        small_image = ChunkyPNG::Image.new(20, 10, ChunkyPNG::Color::WHITE)
        small_image_path = Rails.root.join('spec/fixtures/files/small_signature.png')
        small_image.save(small_image_path)

        small_signature = signature_payload.merge(
          image: Base64.encode64(File.read(small_image_path))
        )

        result = described_class.call(
          document: document,
          signature: small_signature
        )

        expect(result).to start_with("%PDF")
        File.delete(small_image_path)
      end

      it 'handles large signature image' do
        require 'chunky_png'
        large_image = ChunkyPNG::Image.new(500, 250, ChunkyPNG::Color::WHITE)
        large_image_path = Rails.root.join('spec/fixtures/files/large_signature.png')
        large_image.save(large_image_path)

        large_signature = signature_payload.merge(
          image: Base64.encode64(File.read(large_image_path))
        )

        result = described_class.call(
          document: document,
          signature: large_signature
        )

        expect(result).to start_with("%PDF")
        File.delete(large_image_path)
      end
    end

    context 'error handling' do
      it 'raises error when page index is out of bounds' do
        expect do
          described_class.call(
            document: document,
            signature: signature_payload.merge(page: 999)
          )
        end.to raise_error(NoMethodError, /undefined method.*canvas/)
      end

      it 'raises error when document file is missing' do
        document_without_file = create(:document)
        document_without_file.file.purge

        expect do
          described_class.call(
            document: document_without_file,
            signature: signature_payload
          )
        end.to raise_error(StandardError)
      end

      it 'raises error when signature image is invalid base64' do
        invalid_signature = signature_payload.merge(image: "not valid base64!")

        expect do
          described_class.call(
            document: document,
            signature: invalid_signature
          )
        end.to raise_error(HexaPDF::Error)
      end

      it 'raises error when signature image data is corrupted' do
        corrupted_signature = signature_payload.merge(
          image: Base64.encode64("corrupted image data")
        )

        expect do
          described_class.call(
            document: document,
            signature: corrupted_signature
          )
        end.to raise_error(HexaPDF::Error)
      end
    end
  end
end
