module PdfSigner
  class EmbedSignature
    def self.call(...)
      new(...).call
    end

    def initialize(document:, signature:)
      @document = document
      @signature = signature
    end

    def call
      input_pdf = Tempfile.new(["input", ".pdf"])
      output_pdf = Tempfile.new(["output", ".pdf"])
      signature_img = Tempfile.new(["signature", ".png"])

      input_pdf.binmode
      input_pdf.write(@document.file.download)
      input_pdf.rewind

      signature_img.binmode
      signature_img.write(Base64.decode64(@signature[:image]))
      signature_img.rewind

      embed(input_pdf.path, signature_img.path, output_pdf.path)

      File.read(output_pdf.path, encoding: Encoding::ASCII_8BIT)
    ensure
      [input_pdf, output_pdf, signature_img].each(&:close!)
    end

    private

    def embed(input_path, signature_path, output_path)
      pdf = HexaPDF::Document.open(input_path)
      page = pdf.pages[@signature[:page].to_i]

      page.canvas.image(
        signature_path,
        at: [@signature[:x].to_f, @signature[:y].to_f],
        width: @signature[:width].to_f,
        height: @signature[:height].to_f
      )

      pdf.write(output_path)
    end
  end
end
