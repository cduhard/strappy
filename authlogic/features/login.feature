Feature: log in
  In order to use the system
  As a user
  I want to log in
  
Scenario: log in
  Given a user "alex" with the password "testtest"
  When I go to the start page
  And I follow "Log in"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I press "Login"
  Then I should see "Welcome alex"
  And I should see "Login successful!"
 
Scenario: log out
  Given a user "alex" with the password "testtest"
  And "alex" is logged in
  When I go to the account page
  And I follow "Log out"
  Then I should see "Log in"
  And I should see "Logout successful!"
  
Scenario: edit account
  Given a user "alex" with the password "testtest"
  And "alex" is logged in
  When I go to the account page
  And I follow "Edit Account"
  And I fill in "joe" for "Login"
  And I press "Update"
  Then I should see "Account updated!"
