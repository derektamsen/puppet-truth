# file: truth_tag.rb

# Description:
# Add a puppet parser function called 'true_tag'
#   * Takes 2 or 3 argument, the tag type, the role/detail type, and optional a specific value to test for.
#   * Expects a fact 'truth_tags' to be a comma-delimited string containing roles
#
# This function expects the fact 'server_tags' to be comma-delimited
#   Each value in server_tags must be of the format described above.
#   Roles are expected to be of format: "role:<role>=true"
#   For example, the role 'loadbalancer' is "role:loadbalancer=true"
#
# To help troubleshoot place the following in the requesting class file
#   notice has_role(x)
# Which will print to the puppet master's log file the return result
#
# Facter output for 'server_tags': role:loadbalancer=true,role:db=false,role:hadoop-worker=false,role:hadoop-master=false,role:www=false,site:loc=us-ca-sf

module Puppet::Parser::Functions
  newfunction(:truth_tag, :type => :rvalue) do |args|

    # load facter because we will need it later
    require 'rubygems'
    require 'facter'
    
    # set the base fact to look for in facter
    factbase = 'truth_tags'
    
    # Lookup the tags from facter based on the number of args inbound
    case args.length
    when 3
      # in: from truth_tag("x", "y", "z")
      namespace = args[0].to_s.downcase.chomp
      predicate = args[1].to_s.downcase.chomp
      value = args[2].to_s.downcase.chomp
      
      # search facter for values
      # Check to see if values match at a more specific level then return true/false back to caller
      if lookupvar("#{factbase}").split(", ").include?("#{namespace}") then
        # base debug
        #puts "debug #{factbase}_#{namespace}"
        if lookupvar("#{factbase}_#{namespace}").split(", ").include?("#{predicate}") then
          # lvl2 debug
          #puts "debug #{factbase}_#{namespace}_#{predicate}"
          if lookupvar("#{factbase}_#{namespace}_#{predicate}").split(", ").include?("#{value}") then
            # lvl3 debug
            #puts "debug #{factbase}_#{namespace}_#{predicate}=#{value}"
            true
          else
            #raise "facter does not have #{factbase}_#{namespace}_#{predicate}=#{value}"
            false
          end # end lvl3 check
        else
          #raise "facter does not have #{factbase}_#{namespace}_#{predicate}"
          false
        end # end lvl2 check
      else
        #raise "facter does not have #{factbase}_#{namespace}"
        false
      end # end base check
      
    when 2
      # in: from truth_tag("x", "y")
      namespace = args[0].to_s.downcase.chomp
      predicate = args[1].to_s.downcase.chomp
      
      # search facter for values
      # Check to see if values match at a more specific level then return true/false back to caller
      if lookupvar("#{factbase}").split(", ").include?("#{namespace}") then
        # base debug
        #puts "debug #{factbase}_#{namespace}"
        if lookupvar("#{factbase}_#{namespace}").split(", ").include?("#{predicate}") then
          # lvl2 debug
          #puts "debug #{factbase}_#{namespace}_#{predicate}"
          true
        else
          #raise "facter does not have #{factbase}_#{namespace}_#{predicate}"
          false
        end # end lvl2 check
      else
        #raise "facter does not have #{factbase}_#{namespace}"
        false
      end # end base check
      
    when 1
      # in: from truth_tag("x")
      namespace = args[0].to_s.downcase.chomp
      
      # search facter for values
      # Check to see if values match at a more specific level then return true/false back to caller
      if lookupvar("#{factbase}").split(", ").include?("#{namespace}") then
        # base debug
        #puts "debug #{factbase}_#{namespace}"
        true
      else
        #raise "facter does not have #{factbase}_#{namespace}"
        false
      end # end base check
      
    end # end case statement for args length
  end # puppet function truth_tag
end # module Puppet::Parser::Functions
