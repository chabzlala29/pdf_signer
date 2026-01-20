class DocumentsController < ApplicationController
  def create
    document = Document.create!(
      uuid: SecureRandom.uuid,
      expires_at: 1.hour.from_now
    )

    document.file.attach(params.require(:file))
    raise "Invalid file" unless document.file.content_type == "application/pdf"

    render json: {
      id: document.uuid,
      sign_url: sign_document_url(document)
    }
  end

  def show
    document = find_document
    send_data document.file.download,
              filename: "document.pdf",
              type: "application/pdf"
  end

  def sign
    document = find_document

    result = PdfSigner::EmbedSignature.call(
      document: document,
      signature: signature_params
    )

    send_data result,
              filename: "signed.pdf",
              type: "application/pdf"
  end

  private

  def find_document
    Document.find_by!(uuid: params[:id])
  end

  def signature_params
    params.require(:signature).permit(
      :image,
      :page,
      :x,
      :y,
      :width,
      :height
    )
  end
end
