# filename: load_truth_tags.rb

# Description:
# reads #{tagfile} on nodes and sets a custom facts based on the values in that file
# Structure of /etc/truth_tags.yml:
#      <first level>:
#          - <second level> - string nested under <first level> if there are multiple
#                             levels they get nested into an array below <first level>
#      <first level 2>:
#          <second level>: <value> - Hash nested under <first level>. If there are multiple
#                                    levels they get nested as key => value in a hash below
#                                    the first level.
#
# Tips:
# The yaml file gets loaded into a nested hashed variable in this script as loaded_tagfile.
# You can query the first level by using loaded_tagfile.keys

require 'timeout'
require 'net/https'
require 'uri'
require 'yaml'
require 'digest/md5'

# ------ Enable/Disable $debug messages ------
$debug = false
# ------

begin
  Timeout.timeout(10) {
    
begin # Exception tracking

# Location of configuration file to parse into facter
$configdir = '/etc'
$yamlfile = 'truth_tags.yml'
$tagfile = "#{$configdir}/#{$yamlfile}"

# determine the hostname to help locate the correct certificate
def hostname
  puts "def hostname" if $debug
  # get hostname from system and remove trailing new line.
  tmphostname = `hostname`.chomp
  
  # Check for null hosts and other known malformed hostnames to try and correct them.
  case tmphostname
  when ""
    raise "hostname is null"
  else
    puts "hostname is #{tmphostname}" if $debug
    return tmphostname
  end # end hostname check
  
end # End hostname

# Call this to make a connection to puppet's rest api.
# It is called by running apitruthtag("content") or apitruthtag("metadata")
# it will then return the data which can be stored any way you want
def apitruthtag(calltype)
  puts "def apitruthtag" if $debug
  
  sslbasedir = '/etc/puppet/ssl'
  sslprivdir = sslbasedir + '/private_keys'
  sslpubdir = sslbasedir + '/certs'
  sslcafile = sslpubdir + '/ca.pem'

  datatype = calltype

  proto = 'https'
  server = 'puppet'
  port = '8140'
  path = '/production/file_' + datatype + '/truth_private/truth_tags.yml'

  uri = URI.parse(proto + '://' + server + ':' + port + path)

  http = Net::HTTP.new(uri.host, uri.port)

  http.use_ssl = true if uri.scheme == 'https'

  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  header = {'Accept' => 'yaml'}
  http.ca_file = sslcafile
  http.key = OpenSSL::PKey::RSA.new(File.read(sslprivdir + '/' + hostname + '.pem'))
  http.cert = OpenSSL::X509::Certificate.new(File.read(sslpubdir + '/' + hostname + '.pem'))

  http.start {|conn|
    request = Net::HTTP::Get.new(uri.request_uri, header)
    $response = conn.request(request)
  }
  
  
  # Check to make sure we got some data back
  if $response != nil
    # Check to see if we have a good server response before saving the variable
    puts "check code " + $response.code if $debug
    if (($response.code < "300") and ($response.code >= "200"))
      return $response.body
    else
      raise "server did not return an acceptable response code"
    end # end server response code check
  else
    raise "No response from #{server}"
  end # end nil response check
  
end # end apitruthtag


# Function to download the truth tags file from the puppet rest api
def apitruthdownload(filename)
  puts "def apitruthdownload" if $debug
  
  # get the content from the puppet server and save it to yaml
  puts "writting: " + filename if $debug
  File.open(filename, 'w', 0600) do |out|
    out.write(YAML.load(apitruthtag("content")).content)
    puts "written file with: " + YAML.load(apitruthtag("content")).content if $debug
  end
  
end # End apitruthdownload

# Load the truth tag yaml file into facter
def loadtags
  require 'facter'
  puts "def loadtags" if $debug
  
  
  # Ready the yaml config file "tagfile" into loaded_tagfile
  loaded_tagfile = YAML.load_file($tagfile)

   # Load the keys (first level outline) into facter as fact "truth_tags"
   #
   # This can later be used a reference to see what types of tags are on the system.
   # The goal is to be able to call "facter truth_tags" and get back a list of every
   # installed tag type. Then the user can drill into "facter truth_tags_<second level>" for
   # the sub items. If the sub type is a hash that will go one additional level.
   # ex. "facter truth_tags_<second level>_<third level>"
   Facter.add("truth_tags") do
     setcode {
       loaded_tagfile.keys.join(", ").downcase
     }
   end
   # $debug to see what was loaded into facter
   puts "truth_tags = " + Facter.value("truth_tags") if $debug

   # Load the second level of the outline into facter. However, because of how yaml works
   # we need to determine the class of each object and act slightly differently on each type.
   # So we load each first level key and detect what type each is.
   loaded_tagfile.each_key { |key|
     case loaded_tagfile[key]
     when Hash
       # If the key is a hash (loc => {Country=us, State=CA}) then create a three level fact.
       # "truth_tags_<second level>_<third level>"
       # Ex. truth_tags_loc_Country => us
       loaded_tagfile[key].each_key { |subkey|
         # Add an index so we can find the possible values in the sub hash later
         Facter.add("truth_tags_#{key}") do
           setcode {
             loaded_tagfile[key].keys.join(", ").downcase
           }
         end

         # Add the subitems from the hash based on the subkey
         Facter.add("truth_tags_#{key}_#{subkey}") do
           setcode {
             loaded_tagfile[key][subkey].to_s.downcase
           }
         end
         # $debug to see what was loaded into facter
         puts "truth_tags_#{key}_#{subkey} = " + Facter.value("truth_tags_#{key}_#{subkey}") if $debug
       }

     when Array
       # if the key is an array just join it at the "," and unique it to remove duplicate values.
       # can be accessed via "truth_tags_<second level>"
       # Ex. truth_tags_roles => www, db, loadbalancer
       Facter.add("truth_tags_#{key}") do
         setcode {
           loaded_tagfile[key].uniq.join(", ").downcase
         }
       end
       # $debug to see what was loaded into facter
       puts "truth_tags_#{key} = " + Facter.value("truth_tags_#{key}") if $debug

     when String
       # If it is a string just add it as is to a fact matching it's key
       # It is stored as truth_tags_<second level>
       # Ex. truth_tags_env => production
       Facter.add("truth_tags_#{key}") do
         setcode {
           loaded_tagfile[key].downcase
         }
       end
       # $debug to see what was loaded into facter
       puts "truth_tags_#{key} = " + Facter.value("truth_tags_#{key}") if $debug
     # Raise and error if nothing matches
     else raise "The nested hash has an unknown value in it." #unknown class
     end
   }
end # End loadtags

def calclocaltruthmd5
  puts "def calclocaltruthmd5" if $debug
  
  # Calulate the md5 of the truth_tags file on disk so we can compare it with that from the server
  localmd5 = Digest::MD5.hexdigest(File.read($tagfile)).gsub(/^/,'{md5}')
  puts "local md5 hash: #{localmd5}" if $debug
  return localmd5
end # end calclocaltruthmd5

def calcservertruthmd5
  puts "def calcservertruthmd5" if $debug
  
  # call the api to get the md5 of file on server
  servermd5tmp = YAML.load(apitruthtag("metadata"))
  puts "server body: #{apitruthtag("metadata")}" if $debug
  puts "server yaml loaded: #{servermd5tmp}" if $debug
  servermd5 = servermd5tmp.checksum
  puts "server md5 hash: #{servermd5}" if $debug
  if servermd5 == nil then
    raise "could not get md5 hash metadata from puppetmaster"
  else
    return servermd5
  end # end md5 nil check
end # end calcservertruthmd5


# Check to see if the config file exists and is readable
puts "readable? " + $tagfile if $debug
if File.readable?($tagfile) then
  
  localtruthmd5 = calclocaltruthmd5
  servertruthmd5 = calcservertruthmd5
  
  puts "check hashes: " + localtruthmd5 + " vs " + servertruthmd5 if $debug
  if localtruthmd5 != servertruthmd5
    # get the content from the server and write it locally
    puts "downloading tag file from server because md5 did not match" if $debug
    apitruthdownload($tagfile)
    
    # recalculate the tag local file hash to see if the new content matches
    localtruthmd5 = calclocaltruthmd5
    
    puts "check#2 hashes: " + localtruthmd5 + " vs " + servertruthmd5 if $debug
    
    if localtruthmd5 == servertruthmd5
      puts "calling loadtags" if $debug
      loadtags
    else
      raise "something happened when downloading the tagfile"
    end # end downloaded file hash check
  else
    puts "hashes match those on puppetmaster." if $debug
    loadtags
  end # end server - client tag file check
  
# Raise an error if something goes wrong with getting the tag file.
# download a new file from the server and save it locally
else
  puts "file did not exist on disk. Downloading a new copy." if $debug
  apitruthdownload($tagfile)
  
  localtruthmd5 = calclocaltruthmd5
  servertruthmd5 = calcservertruthmd5
  
  puts "check#3 hashes: " + localtruthmd5 + " vs " + servertruthmd5 if $debug
  
  if localtruthmd5 == servertruthmd5
    puts "calling loadtags2" if $debug
    loadtags
  else
    raise "something happened when downloading the tagfile"
  end # end downloaded file hash check
end

rescue => exception
  puts exception
  puts exception.inspect
  puts exception.backtrace
end # End exception inspection
}
rescue Timeout::Error
  puts "Err: ... load_truth_tags.rb facts not loaded."
end # End fact timeout