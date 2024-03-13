# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contact info. Example using compositional keyword: oneOf' do
  # class PhoneContact
  #   include EasyTalk::Model

  #   define_schema do
  #     property :phone_number, String, pattern: '^\\+?[1-9]\\d{1,14}$'
  #   end
  # end

  # class EmailContact
  #   include EasyTalk::Model

  #   define_schema do
  #     property :email, String, format: 'email'
  #   end
  # end

  # class Contact
  #   include EasyTalk::Model

  #   define_schema do
  #     title 'Contact Info'
  #     property :contact, one_of(PhoneContact, EmailContact)
  #   end
  # end

  # context 'json schema' do
  #   it 'returns a json schema for the book class' do
  #     puts Contact.json_schema
  #     expect(Book.json_schema).to include_json('')
  #   end
  # end
end
