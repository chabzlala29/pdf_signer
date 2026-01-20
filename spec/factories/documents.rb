FactoryBot.define do
  factory :document do
    uuid { SecureRandom.uuid }
    expires_at { 30.days.from_now }

    after(:build) do |document|
      # Create a valid test PDF using HexaPDF
      pdf = HexaPDF::Document.new
      pdf.pages.add
      
      pdf_io = StringIO.new
      pdf.write(pdf_io)
      pdf_io.rewind
      
      document.file.attach(
        io: pdf_io,
        filename: "test.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
