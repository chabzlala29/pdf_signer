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
    end
  end
end
