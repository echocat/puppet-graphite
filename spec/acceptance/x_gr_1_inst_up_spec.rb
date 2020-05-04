require 'spec_helper_acceptance'

hosts_as('graphite_1').each do |graphite_host|

  describe "install/update to Graphite 1.1 on host #{graphite_host}" do
    let(:graphite_version){ '1.1.7' }
    let(:django_version){ '1.11' }
    let(:django_tagging_version){ '0.4.6' }
    let(:twisted_version){ '20.3.0' }

    it 'has to delete the existing django db to work around failures migrating the database from 0.9' do
      on(graphite_host, 'rm -f /opt/graphite/storage/graphite.db || exit 0')
    end

    context 'install or upgrade Graphite' do
      # Using puppet_apply as a helper
      it 'should apply with no errors' do
        pp = <<-EOS
          class { 'graphite': 
                secret_key                => '123456789', 
                gr_base_dir               => '/opt/graphite',
                gr_django_init_command    => 'PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py migrate --setting=graphite.settings --fake-initial',
                gr_django_init_provider   => 'shell',
                gr_carbon_ver             => '#{graphite_version}',
                gr_graphite_ver           => '#{graphite_version}',
                gr_whisper_ver            => '#{graphite_version}',
                gr_django_ver             => '#{django_version}',
                gr_django_tagging_ver     => '#{django_tagging_version}',
                gr_twisted_ver            => '#{twisted_version}',
          }
        EOS

        apply_manifest_on(graphite_host, pp, :catch_failures => true)
      end

      it 'should send metric data to carbon' do
        result = on(graphite_host, 'echo "one.metric 42 `date +%s`" | nc -N 127.0.0.1 2003')
        expect(result.exit_code).to eq 0
      end

      it 'should get data from graphite' do
        result = on(graphite_host, "sleep 10 && curl -s 'http://127.0.0.1/render?target=one.metric&format=raw&from=-5min' | grep 'one.metric,.*42.0'")
        expect(result.exit_code).to eq 0
      end

      it 'exist only one link to the egg-info of graphite in the python lib directory' do
        result = on(graphite_host, "test `ls -d /usr/local/lib/python2.7/dist-packages/graphite_web*.egg-info | wc -l` -eq 1")
        expect(result.exit_code).to eq 0
      end

      it 'exist only one egg-info of graphite in the installation directory' do
        result = on(graphite_host, "test `ls -d /opt/graphite/webapp/graphite_web*.egg-info | wc -l` -eq 1")
        expect(result.exit_code).to eq 0
      end

      it 'exist only one link to the egg-info of cabon in the python lib directory' do
        result = on(graphite_host, "test `ls -d /usr/local/lib/python2.7/dist-packages/carbon*.egg-info | wc -l` -eq 1")
        expect(result.exit_code).to eq 0
      end

      it 'exist only one egg-info of carbon in the installation directory' do
        result = on(graphite_host, "test `ls -d /opt/graphite/lib/carbon*.egg-info | wc -l` -eq 1")
        expect(result.exit_code).to eq 0
      end
    end
  end

end
