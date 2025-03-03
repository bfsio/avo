# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  roles                  :json
#  birthday               :date
#  custom_css             :text
#  team_id                :bigint
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active                 :boolean          default(TRUE)
#  slug                   :string
#
class User < ApplicationRecord
  ACCOUNT_STRUCT = Struct.new(:id, :name) unless const_defined?(:ACCOUNT_STRUCT)

  extend FriendlyId
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  validates :first_name, presence: true
  validates :last_name, presence: true

  has_one :post
  has_one :comment
  has_one :fish
  has_many :posts, inverse_of: :user
  has_many :people
  has_many :spouses
  has_many :comments
  has_and_belongs_to_many :projects, inverse_of: :users
  has_many :team_memberships
  has_many :teams, through: :team_memberships, inverse_of: :admin
  has_one_attached :cv

  friendly_id :name, use: [:slugged, :finders]

  scope :active, -> { where active: true }
  scope :admins, -> { where "(roles->>'admin')::boolean is true" }
  scope :non_admins, -> { where "(roles->>'admin')::boolean != true" }

  # We're using a setter here because we want to test that the field is working properly with a non-db backed field.
  attr_writer :permissions

  def is_admin?
    roles.present? && roles["admin"].present?
  end

  def name
    "#{first_name} #{last_name}"
  end

  def notify(text)
    # notify about text
  end

  def avatar
    options = {
      default: "",
      size: 100
    }

    query = options.map { |key, value| "#{key}=#{value}" }.join("&")
    md5 = Digest::MD5.hexdigest(email.strip.downcase)

    URI::HTTPS.build(host: "www.gravatar.com", path: "/avatar/#{md5}", query: query).to_s
  end

  def avo_title
    is_admin? ? "Admin" : "Member"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["active", "birthday", "created_at", "custom_css", "email", "encrypted_password", "first_name", "id", "last_name", "remember_created_at", "reset_password_sent_at", "reset_password_token", "roles", "slug", "team_id", "updated_at"]
  end

  # Simulate accounts association
  def accounts
    [
      ACCOUNT_STRUCT.new(1, "Foo"),
      ACCOUNT_STRUCT.new(2, "Bar")
    ]
  end

  def is_developer?
    true
  end

  def permissions
    {
      create: true,
      update: false,
      read: true,
      delete: true,
    }
  end

  def some_token = @some_token ||= SecureRandom.hex(64)
end
