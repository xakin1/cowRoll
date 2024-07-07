defmodule CowRollWeb.ErrorCodes do
  @moduledoc """
  This module contains definitions of error codes used throughout the application.
  """
  @empty_folder_name "EMPTY_FOLDER_NAME"
  @empty_file_name "EMPTY_FILE_NAME"
  @empty_user_name "EMPTY_USER_NAME"
  @empty_password "EMPTY_PASSWORD"

  @file_not_found "FILE_NOT_FOUND"
  @directory_not_found "DIRECTORY_NOT_FOUND"
  @parent_not_found "PARENT_NOT_FOUND"

  @sheet_not_found "SHEET_NOT_FOUND"
  @empty_sheet_name "EMPTY_SHEET_NAME"
  @sheet_name_already_exits "SHEET_NAME_ALREADY_EXISTS"

  @file_name_already_exits "FILE_NAME_ALREADY_EXISTS"
  @invalid_user_id "INVALID_USER_ID"
  @directory_name_already_exits "DIRECTORY_NAME_ALREADY_EXISTS"
  @parent_into_child "PARENT_INTO_CHILD"

  @user_name_already_exits "USER_NAME_ALREADY_EXISTS"
  @user_not_found "USER_NOT_FOUND"
  @invalid_credentials "INVALID_CREDENTIALS"
  @minimun_length "MINIMUN_LENGTH"
  @digits "DIGITS"
  @uper_case "UPER_CASE"
  @lower_case "LOWER_CASE"
  @special_characteres "SPECIAL_CHARACTERES"

  @spec empty_folder_name() :: <<_::136>>
  def empty_folder_name, do: @empty_folder_name

  @spec empty_file_name() :: <<_::120>>
  def empty_file_name, do: @empty_file_name

  @spec empty_user_name() :: <<_::120>>
  def empty_user_name, do: @empty_user_name

  @spec sheet_not_found() :: <<_::120>>
  def sheet_not_found, do: @sheet_not_found

  def empty_sheet_name, do: @empty_sheet_name

  @spec sheet_name_already_exits() :: <<_::200>>
  def sheet_name_already_exits, do: @sheet_name_already_exits

  @spec empty_password() :: <<_::112>>
  def empty_password, do: @empty_password

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

  @spec user_name_already_exits() :: <<_::192>>
  def user_name_already_exits, do: @user_name_already_exits

  @spec directory_name_already_exits() :: <<_::232>>
  def directory_name_already_exits, do: @directory_name_already_exits

  @spec parent_into_child() :: <<_::136>>
  def parent_into_child, do: @parent_into_child

  @spec user_not_found() :: <<_::112>>
  def user_not_found, do: @user_not_found

  def invalid_credentials, do: @invalid_credentials

  def minimun_length, do: @minimun_length

  def digits, do: @digits

  def lower_case, do: @lower_case

  def uper_case, do: @uper_case

  def special_characteres, do: @special_characteres
end
