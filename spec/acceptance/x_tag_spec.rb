require 'spec_helper_acceptance'

hosts_as('graphite_1').each do |graphite_host|

  describe "graphite 1.1 install/update on host #{graphite_host}" do
    let(:graphite_version){ '1.1.7' }
    let(:django_version){ '1.11' }
    let(:django_tagging_version){ '0.4.6' }
    let(:twisted_version){ '20.3.0' }

    it 'has to delete the existing django db to work around failures migrating the database from 0.9' do
      on(graphite_host, 'rm -f /opt/graphite/storage/graphite.db || exit 0')
    end

    context 'install or upgrade Graphite 1.1 with tag support' do
      # Using puppet_apply as a helper
      it 'should work with no errors' do
        pp = <<-EOS
          class { 'graphite': 
                secret_key                => '123456789', 
                gr_base_dir               => '/opt/graphite',
                gr_django_init_command    => 'PYTHONPATH=/opt/graphite/webapp /usr/local/bin/django-admin.py migrate --setting=graphite.settings --fake-initial && chown www-data /opt/graphite/storage/log/*.log',
                gr_django_init_provider   => 'shell',
                gr_carbon_ver             => '#{graphite_version}',
                gr_graphite_ver           => '#{graphite_version}',
                gr_whisper_ver            => '#{graphite_version}',
                gr_django_ver             => '#{django_version}',
                gr_django_tagging_ver     => '#{django_tagging_version}',
                gr_twisted_ver            => '#{twisted_version}',
                gr_tags_enable            => true,
          }
        EOS

        apply_manifest_on(graphite_host, pp, :catch_failures => true)
      end

      it 'should send tagged data' do
        result = on(graphite_host, 'echo "data;arg=key 42 `date +%s`" | nc -N 127.0.0.1 2003')
        expect(result.exit_code).to eq 0
      end

      it 'graphite should have received the data' do
        result = on(graphite_host, "sleep 10 && curl -s 'http://127.0.0.1/render?target=seriesByTag(\"arg=key\")&format=raw&from=-5min' | grep 'arg=key,.*42.0'")
        expect(result.exit_code).to eq 0
      end
    end
  end
end

