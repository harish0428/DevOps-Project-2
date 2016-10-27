ec2_vpc { 'DevOpsProjVPC':
  ensure       => present,
  region       => 'us-east-1',
  cidr_block   => '10.0.0.0/16',
}

ec2_securitygroup { 'DevOpsProjSG':
  ensure      => present,
  region      => 'us-east-1',
  vpc         => 'DevOpsProjVPC',
  description => 'Security group for VPC',
  ingress     => [{
    security_group => 'DevOpsProjSG',
  },{
    protocol => 'tcp',
    port     => 22,
    cidr     => '0.0.0.0/0'
  }
  {
    protocol => 'https',
    port     => 443,
    cidr     => '0.0.0.0/0'
  }
  {
    protocol => 'http',
    port     => 80,
    cidr     => '0.0.0.0/0'
  }
  ]
}

ec2_vpc_subnet { 'DevOpsSubnet':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'DevOpsProjVPC',
  cidr_block        => '10.0.0.0/24',
  availability_zone => 'us-east-1c',
  route_table       => 'DevOpsRT',
}

ec2_vpc_internet_gateway { 'DevOpsIGW':
  ensure => present,
  region => 'us-east-1',
  vpc    => 'DevOpsProjVPC',
ec2_vpc_routetable { 'DevOpsRT':
  ensure => present,
  region => 'us-east-1',
  vpc    => 'DevOpsProjVPC',
  routes => [
    {
      destination_cidr_block => '10.0.0.0/16',
      gateway                => 'local'
    },{
      destination_cidr_block => '0.0.0.0/0',
      gateway                => 'DevOpsIGW'
    },
  ],
}
}

ec2_instance { 'DevOpsWebinstance1':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'DevOpsProjVPC',
  availability_zone => 'us-east-1a',
  image_id          => 'ami-2d39803a',
  instance_type     => 't2.micro',
  monitoring        => true,
  security_groups   => 'DevOpsProjSG',
  user_data         => template('apachepuppet.sh'),
}
ec2_instance { 'DevOpsWebinstance2':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'DevOpsProjVPC',
  availability_zone => 'us-east-1b',
  image_id          => 'ami-2d39803a',
  instance_type     => 't2.micro',
  monitoring        => true,
  security_groups   => 'DevOpsProjSG',
  user_data         => template('apachepuppet.sh'),
}
elb_loadbalancer { 'DevOpsLB':
  ensure               => present,
  region               => 'us-east-1',
  availability_zones   => ['us-east-1a', 'us-east-1b'],
  instances            => ['DevOpsWebinstance1', 'DevOpsWebinstance2'],
  security_groups      => ['DevOpsProjSG'],
  listeners            => [{
    protocol           => 'HTTP',
    load_balancer_port => 80,
    instance_protocol  => 'HTTP',
    instance_port      => 80,
  },{
    protocol           => 'HTTPS',
    load_balancer_port => 443,
    instance_protocol  => 'HTTPS',
    instance_port      => 8080,
  }],
}


ec2_launchconfiguration { 'DevOpsLConfiguration':
  ensure          => present,
  security_groups => ['DevOpsProjSG'],
  region          => 'us-east-1',
  image_id        => 'ami-2d39803a',
  instance_type   => 't2.micro',
}

ec2_autoscalinggroup { 'DevOpsASG':
  ensure               => present,
  min_size             => 2,
  max_size             => 2,
  region               => 'us-east-1',
  launch_configuration => 'DevOpsLConfiguration',
  availability_zones   => ['us-east-1a', 'us-east-1b'],
}

ec2_scalingpolicy { 'scaleout':
  ensure             => present,
  auto_scaling_group => 'DevOpsASG',
  scaling_adjustment => +1,
  adjustment_type    => 'ChangeInCapacity',
  region             => 'us-east-1',
}

ec2_scalingpolicy { 'scalein':
  ensure             => present,
  auto_scaling_group => 'DevOpsASG',
  scaling_adjustment => -1,
  adjustment_type    => 'ChangeInCapacity',
  region             => 'us-east-1',
}

cloudwatch_alarm { 'AddCapacity':
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 75,
  comparison_operator => 'GreaterThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => 'DevOpsASG',
  }],
  evaluation_periods  => 2,
  alarm_actions       => 'scaleout',
  region              => 'us-east-1',
}

cloudwatch_alarm { 'RemoveCapacity':
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 35,
  comparison_operator => 'LessThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => 'DevOpsASG',
  }],
  evaluation_periods  => 2,
  region              => 'us-east-1',
  alarm_actions       => 'scalein',
}

