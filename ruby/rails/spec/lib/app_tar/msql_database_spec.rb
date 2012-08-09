require 'spec_helper'

describe AppTar::MysqlDatabase do
  
  before(:each) do
    @db = AppTar::MysqlDatabase.new(:tables => ['T1', 'T2'])
    {
      :database => 'DB',
      :username => 'USER',
      :password => 'PW',
      :host     => 'HOST',
      :port     => 'PORT',
      :mysql_bin_dir => '/m',
    }.each do |k,v|
      @db.db_config.stub!(k).and_return(v)
    end
  end
  
  describe "credentials()" do
    def credentials
      %w(--host=HOST --port=PORT --user=USER --password=PW)
    end
    
    it "no switches" do
      expected = ['/m/mysql']
      expected += credentials
      expected << 'DB'
      @db.credentials('mysql').should == expected
    end
    
    it "with switches" do
      expected = ["/m/mysqldump", credentials, "--foo", "DB"].flatten
      @db.credentials('mysqldump', '--foo').should == expected

      expected = ["/m/mysql", credentials, "--foo bar", "--baz", "DB"].flatten
      @db.credentials('mysql', '--foo bar', '--baz').should == expected
    end
    
    it "no password" do
      @db.db_config.stub!(:password).and_return('')
      @db.credentials('mysql', '--foo bar', '--baz').should == ["/m/mysql", "--host=HOST", "--port=PORT", "--user=USER", "--foo bar", "--baz", "DB"]
    end
    
  end
  
  it "save_insert_cmd" do
    @db.save_insert_cmd.should include('T1')
    @db.save_insert_cmd.should include('T2')
  end

  it "insert_filename" do
    @db.insert_filename.should == 'insert.sql'
  end
  
  it "delete_filename" do
    @db.delete_filename.should == 'delete.sql'
  end
  
end
