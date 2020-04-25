require 'spec_helper_acceptance'

describe 'graphite class' do

  context 'enable tags' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      class { 'graphite': 
            secret_key                => '123456789', 
            gr_base_dir               => '/opt/graphite',
            # migrate dashboard fails with --fake-initial
            gr_django_init_command    => 'PYTHONPATH=/opt/graphite/webapp python manage.py migrate --fake-initial || PYTHONPATH=/opt/graphite/webapp python manage.py migrate --fake dashboard && PYTHONPATH=/opt/graphite/webapp python manage.py migrate --fake-initial',
            gr_django_init_provider   => 'shell',
            gr_carbon_ver             => '1.1.7',
            gr_graphite_ver           => '1.1.7',
            gr_whisper_ver            => '1.1.7',
            gr_django_ver             => '1.9',
            gr_twisted_ver            => '20.3.0',
            gr_tags_enable            => true,
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    it 'should send tagged data' do
      result = shell('echo "data;arg=key 42 `date +%s`" | nc -N 127.0.0.1 2003')
      expect(result.exit_code).to eq 0
    end

    it 'graphite should have received the data' do
      result = shell("sleep 10 && curl -s 'http://127.0.0.1/render?target=seriesByTag(\"arg=key\")&format=raw&from=-5min' | grep 'arg=key,.*42.0'")
      expect(result.exit_code).to eq 0
    end
  end
end

