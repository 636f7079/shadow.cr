require "terminal_table"
require "option_parser"
require "colorize"
require "openssl"
require "secrets"
require "crc32"
require "json"
require "yaml"
require "sqlite3"
require "file_utils"
require "openssl/hmac"
require "../lib/shield/src/shield/*"
require "./shadow/*"

module Shadow::CommandParser
  case ARGV[0]?
  when "version", "-v"
    puts <<-EOF
    Version:
      Shadow.cr :: CLI Password Vault
      _Version_ :: #{VERSION} (2019.09.22)
    EOF
  when "help", "-h"
    puts <<-EOF
    Usage: shadow [command]
    Command:
      version, --version, -v           Display Version Information of Shadow.cr
      help, --help, -h                 Show this Shadow.cr: Password Vault Help
      init                             Initialize The Shadow.cr Configuration file
      rename                           Rename The Shadow.cr Database File Name
      bind                             Bind The Shadow.cr Database File Location
      move                             Move The Shadow.cr Database File Location
      destroy                          Destroy The Shadow.cr Configuration file
      --summary-table, -i              View all Vault Tables (i.e. Name, RowCount)
      -c [tableName]                   Create a Vault Table by ARGV Table Name
      -d [tableName]                   Delete a Vault Table by ARGV Table Name
      -s [tableName]                   Select a Vault Table by ARGV Table Name
      -r [tableName]                   Rename the Vault Table by ARGV Table Name
      --create-table                   Create a Vault Table by Enter Table Name
      --delete-table                   Delete a Vault Table by Enter Table Name
      --select-table                   Select a Vault Table by Enter Table Name
      --rename-table                   Rename the Vault Table by Enter Table Name
    Options:
      --resign                         Resign the MasterKey by PKCS5 Pbkdf2HMAC
      --delete                         Delete Record by Column Name and Value
      --create                         Create a Record by Some Steps
      --update                         Update The Value by rowId, Column Name
      --summary                        View all Row Records in The Table
      --detail                         View all Row Records in The Table (More)
      --search                         Find Records by Column Name and Value
      --decrypt                        Decrypt Record by Column Name and Value
    EOF
  when "init"
    Config.init_config do
      Config.init_database
    end
  when "rename"
    Config.rename_database
  when "bind"
    Config.bind_database
  when "move"
    Config.move_database
  when "reset"
    Config.reset_database
  when "destroy"
    Config.destroy
  when Nil, String
    Table.new Option.new
  end
end
