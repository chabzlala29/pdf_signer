require "rails_helper"

describe "Documents", type: :request do
  describe "POST /documents" do
    it "creates a document and returns uuid and sign_url" do
      post "/documents", params: { file: fixture_file_upload("test.pdf", "application/pdf") }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("id")
      expect(json).to have_key("sign_url")
    end
  end

  describe "GET /documents/:id" do
    it "returns the PDF file" do
      document = create(:document)
      get "/documents/#{document.uuid}"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to match("application/pdf")
    end

    it "returns 404 for non-existent document" do
      get "/documents/invalid-uuid"

      expect(response).to have_http_status(:not_found)
    end
  end
end
