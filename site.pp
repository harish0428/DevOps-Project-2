node 'project.puppetagent*.com' {  
  class { 'apache':    
    default_mods => false, 
  }  
  include apache::mod::ssl  

  apache::vhost { 'project.puppetagent*.com-http':    
    servername      => 'project.puppetagent*.com',    
    port            => '80',    
    docroot         => '/var/www/html/',    
    redirect_status => 'permanent',    
    redirect_dest   => 'https://project.puppetagent*.com/',  
  }  

  apache::vhost { 'project.puppetagent*.com-https':    
    servername      => 'project.puppetagent*.com',    
    port            => '443',    
    docroot         => '/var/www/html/',    
    ssl             => true,    
  }
}

