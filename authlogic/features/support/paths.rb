def path_to(page_name)
  case page_name
  when /the start page/i
    root_path
  when /the account page/i
    account_path
  else
    raise "Can't find mapping from \"\#{page_name}\" to a path."
  end
end