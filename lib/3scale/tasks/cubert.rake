namespace :cubert do

  desc 'Global Cubert enable, requires per-service enable afterwards'
  task :enable => :environment do
    ThreeScale::Backend::CubertServiceManagementUseCase.global_enable
  end

  desc 'Global Cubert disable'
  task :disable => :environment do
    ThreeScale::Backend::CubertServiceManagementUseCase.global_disable
  end

  desc 'Disables Cubert and cleans all the related keys'
  task :clean => :environment do
    ThreeScale::Backend::CubertServiceManagementUseCase.clean_cubert_redis_keys
  end

  def storage
    ThreeScale::Backend::Storage.instance
  end
end