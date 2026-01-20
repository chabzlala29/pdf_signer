class DeleteExpiredDocumentsJob < ApplicationJob
  queue_as :default

  def perform
    Document.expired.find_each do |doc|
      doc.file.purge_later
      doc.destroy!
    end
  end
end
