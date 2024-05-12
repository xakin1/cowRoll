defmodule CowRollWeb.ErrorCodes do
  @moduledoc """
  This module contains definitions of error codes used throughout the application.
  """
  @empty_folder_name "EMPTY_FOLDER_NAME"
  @empty_file_name "EMPTY_FILE_NAME"
  @file_not_found "FILE_NOT_FOUND"
  @directory_not_found "DIRECTORY_NOT_FOUND"
  @invalid_user_id "INVALID_USER_ID"
  @parent_not_found "PARENT_NOT_FOUND"
  @file_name_already_exits "FILE_NAME_ALREADY_EXISTS"
  @directory_name_already_exits "DIRECTORY_NAME_ALREADY_EXISTS"
  @parent_into_child "PARENT_INTO_CHILD"

  @spec empty_folder_name() :: <<_::136>>
  def empty_folder_name, do: @empty_folder_name
  @spec empty_file_name() :: <<_::120>>
  def empty_file_name, do: @empty_file_name
  @spec file_not_found() :: <<_::112>>
  def file_not_found, do: @file_not_found
  @spec directory_not_found() :: <<_::152>>
  def directory_not_found, do: @directory_not_found
  @spec invalid_user_id() :: <<_::120>>
  def invalid_user_id, do: @invalid_user_id
  @spec parent_not_found() :: <<_::128>>
  def parent_not_found, do: @parent_not_found
  @spec file_name_already_exits() :: <<_::192>>
  def file_name_already_exits, do: @file_name_already_exits
  @spec directory_name_already_exits() :: <<_::232>>
  def directory_name_already_exits, do: @directory_name_already_exits
  @spec parent_into_child() :: <<_::136>>
  def parent_into_child, do: @parent_into_child
end
