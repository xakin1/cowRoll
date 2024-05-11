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

  def empty_folder_name, do: @empty_folder_name
  def empty_file_name, do: @empty_file_name
  def file_not_found, do: @file_not_found
  def directory_not_found, do: @directory_not_found
  def invalid_user_id, do: @invalid_user_id
  def parent_not_found, do: @parent_not_found
  def file_name_already_exits, do: @file_name_already_exits
  def directory_name_already_exits, do: @directory_name_already_exits
end
