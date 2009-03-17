class User < ActiveRecord::Base
  acts_as_authentic :crypto_provider => Authlogic::CryptoProviders::Sha512, 
                    :transition_from_crypto_provider => OldCryptoProvider, 
                    :scope => :account_id,
                    :password_field_validates_length_of_options => { :on => :update, :if => :has_no_credentials? }
                    
                    
                    
                    
  using_access_control
  
  RE_NAME_OK      = /\A[^[:cntrl:]\\<>\/&]*\z/              # Unicode, permissive
  MSG_NAME_BAD    = "^Non-printing characters and \\&gt;&lt;&amp;/ are not allowed."
  
  belongs_to :account
  belongs_to :person
  
  has_many :roles, :dependent => :destroy
  
  validates_presence_of     :account_id
  validates_presence_of     :first_name, :message => "^First name can't be blank."
  validates_format_of       :first_name,     :with => RE_NAME_OK,  :message => MSG_NAME_BAD
  validates_length_of :name, :within => 2..100, :too_long => '^First name is too long (maximum is 100 characters).', :too_short => '^First Name is too short (minimum is 2 characters).', :unless => lambda{|record| record.first_name.blank?}
  

  validates_presence_of     :last_name, :message => "^Last name can't be blank."
  validates_format_of       :last_name,     :with => RE_NAME_OK,  :message => MSG_NAME_BAD
  validates_length_of :name, :within => 2..100, :too_long => '^Last name is too long (maximum is 100 characters).', :too_short => '^Last name is too short (minimum is 2 characters).', :unless => lambda{|record| record.last_name.blank?}

  validates_uniqueness_of :email
  
   
  attr_writer :admin_created #hack to work with declarative auth. don't want to run set_current_user_for_model_security
  
  # Since UserSession.find and UserSession.save will trigger
  # record.save_without_session_maintenance(false) and the 'updated_at', 'last_request_at'
  # fields of user model will be updated every time by authlogic if record (user) found.
  # We need to reset Authorization.current_user instead of giving the update privilege
  # of user model to guest role, and use before_save filter in user model instead of
  # after_find and before_save filters in UserSession model in case of other methods like
  # reset_perishable_token! will call save_without_session_maintenance too.
  before_save :set_current_user_for_model_security
  
  before_save :downcase_email
  
  attr_accessible :email, :password, :password_confirmation, :openid_identifier, :first_name, :last_name, :account_id, :time_zone

  def active?
    active
  end
  
  def activate!(user)
    self.active = true
    self.password = user[:password]
    self.password_confirmation = user[:password_confirmation]
    self.roles.build(:title => 'user')
    save
  end
  
  def role_symbols
    (roles || []).map {|r| r.title.to_sym}    
  end
  
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end
  
  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_activation_instructions(self)
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    Notifier.deliver_activation_confirmation(self)
  end

  def has_no_credentials?
    self.crypted_password.blank? 
  end
  
protected  
  def set_current_user_for_model_security
    Authorization.current_user = self unless @admin_created
  end
  
  def downcase_email
    self.email = self.email.downcase
  end
  
end


