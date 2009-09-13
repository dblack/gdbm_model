require 'active_model'

class GdbmModel
  include ActiveModel::Validations

  attr_accessor :id

  def new_record?
    @new_record
  end

  def dirname
    self.class.dirname
  end

  def self.attributes
    @attributes
  end

  def initialize(attributes = {})
    @new_record = true
    @buffer = {}
    add_attributes_to_buffer(attributes)
  end

  def self.attr_accessor(*args)
    @attributes ||= []
    args.map!(&:to_s)
    args.each do |arg|
      define_method(arg)     { @buffer[arg] }
      define_method(arg+"=") {|val| @buffer[arg] = val }
    end 
    @attributes += args
  end

  def self.inherited(c)
    def c.dirname
      @dirname ||= File.join(
      RAILS_ROOT, "db", name.underscore.pluralize + ".gdbm")
      Dir.mkdir(@dirname) unless File.exist?(@dirname)
      @dirname
    end
  end

  def self.next_dbname
    n = 0
    begin
      FileUtils.touch("#{dirname}/#{n}") if n > 0
      n += 1
    end while File.exist?("#{dirname}/#{n}")
    "#{dirname}/#{n}" 
  end

  def self.create(attributes = {})
    record = new(attributes)
    record.save
    record
  end
    
  def save
    return false unless valid?
    dbname = @dbname || self.class.next_dbname
    GDBMP.open(dbname) do |db|
      self.class.attributes.each do |attr|
        db[attr] = self.send(attr)
      end
    end
    @new_record = false
    @dbname = dbname
    self.id = dbname[/\d+$/].to_i
    true
  end

  def add_attributes_to_buffer(attributes)
    attributes = Hash[*attributes.map {|a,b| [a.to_s, b] }.flatten]
    @buffer.update(attributes)
  end

  def update_attributes(attributes = {})
    add_attributes_to_buffer(attributes)
    save
  end

  def self.find(id)
    dbname = File.join(dirname, id.to_s)
    return nil unless File.exist?(dbname)
    GDBMP.open(dbname) do |db|
      attrs = attributes.map {|attr| [attr, db[attr]] }
      record = self.new(attrs)
      record.instance_variable_set("@dbname", 
        File.join(dirname, id.to_s))
      record
    end
  end
end

if $0 == __FILE__ || $0 =~ /runner/

require 'test/unit'

class Person < GdbmModel
  attr_accessor :name, :age
  validates_presence_of :name
end

class GTest < Test::Unit::TestCase
  def test_initialization
    person = Person.new(:name => "David", :age => 50)
    assert_equal("David", person.name)
  end

  def test_save_record
    @person = Person.new
    @person.name = "David"
    @person.age = 50
    assert(@person.save)
  end

  def test_retrieving_object
    test_save_record
    person = Person.find(@person.id)
    assert(person)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def teardown
    FileUtils.rm_rf(Person.dirname) if File.exist?(Person.dirname.to_s)
  end

  def test_initialize_with_hash
    person = Person.new(:name => "David", :age => 50)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def test_attr_mechanics
    assert_equal(%w{ age name },
      Person.instance_variable_get("@attributes").sort)
  end

  def test_new_record
    person = Person.new
    assert(person.new_record?)
  end

  def test_saving_invalid_record
    person = Person.new
    assert(!person.valid?)
    assert_equal(false, person.save)
  end

  def test_updating_attributes
    person = Person.new(:name => "David", :age => 50)
    person.save
    person.update_attributes(:name => "Black", :age => 51)
    assert_equal("Black", person.name)
    assert_equal(51, person.age)

    black = Person.find(person.id)
    assert_equal("Black", person.name)
    assert_equal(51, person.age)
  end

  def test_create
    person = Person.create(:name => "David", :age => 50)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def test_next_dbname
    assert_equal(Person.dirname + "/1", Person.next_dbname)
    Person.new(:name => "David", :age => 50).save
    assert_equal(Person.dirname + "/2", Person.next_dbname)
  end

  def test_saving_with_existing_id
  end  

  def test_save_with_changes
    book = Book.new(:title => "a", :author => "b", :year => 1999)
    book.title = "Other"
    book.save
    b = Book.find(book.id)
    assert_equal("Other", b.title)
  end
end
end
