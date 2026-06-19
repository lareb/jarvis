class User < ApplicationRecord
  has_many :integration_accounts, dependent: :destroy
  has_many :commands, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
