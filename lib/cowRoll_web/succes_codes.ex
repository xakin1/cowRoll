defmodule CowRollWeb.SuccesCodes do
  @file_updated "FILE_UPDATED"
  @file_deleted "FILE_DELETED"
  @directory_updated "DIRECTORY_UPDATED"
  @directory_deleted "DIRECTORY_DELETED"
  @content_inserted "CONTENT_INSERTED"
  @authentication_ok "AUTHENTICATED_OK"

  @spec file_updated() :: <<_::96>>
  def file_updated, do: @file_updated

  @spec file_deleted() :: <<_::96>>
  def file_deleted, do: @file_deleted

  @spec content_inserted() :: <<_::128>>
  def content_inserted, do: @content_inserted

  @spec directory_updated() :: <<_::136>>
  def directory_updated, do: @directory_updated

  @spec directory_deleted() :: <<_::136>>
  def directory_deleted, do: @directory_deleted

  @spec authentication_ok() :: <<_::128>>
  def authentication_ok, do: @authentication_ok
end
