# -*- coding: utf-8 -*-

require 'oktest'
require 'migr8'
require 'stringio'


Oktest.scope do


  topic Migr8::Migration do

    klass = Migr8::Migration


    topic '#initalize()' do

      spec "[!y4dy3] takes version, author, and desc arguments." do
        mig = klass.new('abcd1234', 'user1', 'desc1')
        ok {mig.version} == 'abcd1234'
        ok {mig.author}  == 'user1'
        ok {mig.desc}    == 'desc1'
      end

    end


    topic '#applied?' do

      spec "[!ebzct] returns false when @applied_at is nil, else true." do
        mig = klass.new()
        ok {mig.applied?} == false
        mig.applied_at = '2013-01-01 12:34:56'
        ok {mig.applied?} == true
      end

    end


    topic '#up_script' do

      spec "[!cfp34] returns nil when 'up' is not set." do
        mig = klass.new()
        mig.up = nil
        ok {mig.up_script} == nil
      end

      spec "[!200k7] returns @up_script if it is set." do
        mig = klass.new()
        mig.up_script = "xxx"
        ok {mig.up_script} == "xxx"
      end

      spec "[!6gaxb] returns 'up' string expanding vars in it." do
        original = <<END
create table ${table} (
  id    serial        primary key;
  name  varchar(255)  not null;
);
create index ${table}_${column}_idx on ${table}(${column});
END
        expanded = <<END
create table sample1 (
  id    serial        primary key;
  name  varchar(255)  not null;
);
create index sample1_name_idx on sample1(name);
END
        mig = klass.new
        mig.up = original
        mig.vars = {'table'=>'sample1', 'column'=>'name'}
        ok {mig.up_script} == expanded
      end

      spec "[!jeomg] renders 'up' script as eRuby template." do
        original = <<END
insert into ${table}(${column}) values
<% comma = "  " %>
<% for name in %w[Haruhi Mikuru Yuki] %>
  <%= comma %>('<%= name %>')
<%   comma = ", " %>
<% end %>
;
END
        expanded = <<END
insert into users(name) values
    ('Haruhi')
  , ('Mikuru')
  , ('Yuki')
;
END
        mig = klass.new
        mig.up = original
        mig.vars = {'table'=>'users', 'column'=>'name'}
        ok {mig.up_script} == expanded
      end

    end


    topic '#down_script' do

      spec "[!e45s1] returns nil when 'down' is not set." do
        mig = klass.new
        mig.down = nil
        ok {mig.down_script} == nil
      end

      spec "[!27n2l] returns @down_script if it is set." do
        mig = klass.new
        mig.down_script = "xxx"
        ok {mig.down_script} == "xxx"
      end

      spec "[!0q3nq] returns 'down' string expanding vars in it." do
        original = <<END
drop index ${table}_${column}_idx;
drop table ${table};
END
        expanded = <<END
drop index sample1_name_idx;
drop table sample1;
END
        mig = klass.new
        mig.down = original
        mig.vars = {'table'=>'sample1', 'column'=>'name'};
        ok {mig.down_script} == expanded
      end

      spec "[!kpwut] renders 'up' script as eRuby template." do
        original = <<END
<% for name in %w[Haruhi Mikuru Yuki] %>
delete from ${table} where ${column} = '<%= name %>';
<% end %>
END
        expanded = <<END
delete from users where name = 'Haruhi';
delete from users where name = 'Mikuru';
delete from users where name = 'Yuki';
END
        mig = klass.new
        mig.down = original
        mig.vars = {'table'=>'users', 'column'=>'name'}
        ok {mig.down_script} == expanded
      end

    end


    topic '#_render()' do

      spec "[!1w3ov] renders string with 'vars' as context variables." do
        mig = klass.new
        mig.vars = {'table'=>'users', 'columns'=>['id', 'name']}
        src = "@table: <%=@table.inspect%>; @columns: <%=@columns.inspect%>;"
        output = mig.__send__(:_render, src)
        ok {output} == '@table: "users"; @columns: ["id", "name"];'
      end

    end


    topic '#applied_at_or()' do

      spec "[!zazux] returns default arugment when not applied." do
        mig = klass.new
        ok {mig.applied?} == false
        ok {mig.applied_at_or('(not applied)')} == '(not applied)'
      end

      spec "[!fxb4y] returns @applied_at without msec." do
        mig = klass.new
        mig.applied_at = '2013-01-01 12:34:56.789'
        ok {mig.applied?} == true
        ok {mig.applied_at_or('(not applied)')} == '2013-01-01 12:34:56'
      end

    end


    topic '#filepath' do

      spec "[!l9t5k] returns nil when version is not set." do
        mig = klass.new
        mig.version = nil
        ok {mig.filepath} == nil
      end

      spec "[!p0d9q] returns filepath of migration file." do
        mig = klass.new
        mig.version = 'abcd1234'
        ok {mig.filepath} == 'migr8/migrations/abcd1234.yaml'
      end

    end


    topic '.load_from()' do

      fixture :mig_filepath do
        content = <<END
# -*- coding: utf-8 -*-
version:   wxyz7890
author:    haruhi
desc:      test migration '#1'
vars:
  - table:  members
  - column: name
  - index:  ${table}_${column}_idx

up: |
  cteate table ${table}(
    id  serial   primary key,
    name  varchar(255)  not null
  );
  create index ${index} on ${table}(${name});

down: |
  drop table ${table};
END
        fpath = "tmp.#{rand().to_s[2..5]}.yaml"
        File.open(fpath, 'w') {|f| f.write(content) }
        at_end { File.unlink(fpath) }
        fpath
      end

      spec "[!fbea5] loads data from file and returns migration object." do |mig_filepath|
        mig = klass.load_from(mig_filepath)
        ok {mig}.is_a?(Migr8::Migration)
        ok {mig.version} == 'wxyz7890'
        ok {mig.author}  == 'haruhi'
        ok {mig.desc}    == 'test migration \'#1\''
      end

      spec "[!sv21s] expands values of 'vars'." do |mig_filepath|
        mig = klass.load_from(mig_filepath)
        ok {mig.vars} == {'table'=>'members', 'column'=>'name',
                          'index'=>'members_name_idx'}
      end

      spec "[!32ns3] not expand both 'up' and 'down'." do |mig_filepath|
        mig = klass.load_from(mig_filepath)
        ok {mig.up} == <<END
cteate table ${table}(
  id  serial   primary key,
  name  varchar(255)  not null
);
create index ${index} on ${table}(${name});
END
        ok {mig.down} == <<END
drop table ${table};
END
      end

    end


  end


end
