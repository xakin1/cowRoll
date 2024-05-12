defmodule CowRollWeb.SuccesCodes do
  @file_updated "FILE_UPDATED"
  @file_deleted "FILE_DELETED"
  @directory_updated "DIRECTORY_UPDATED"
  @directory_deleted "DIRECTORY_DELETED"
  @content_inserted "CONTENT_INSERTED"

  def file_updated, do: @file_updated
  def file_deleted, do: @file_deleted
  def content_inserted, do: @content_inserted
  def directory_updated, do: @directory_updated
  def directory_deleted, do: @directory_deleted
end
