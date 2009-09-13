require 'test_helper'

class Human < GdbmModel
  attr_accessor :name, :age
  validates_presence_of :name
end

class GdbmModelTest < ActiveSupport::TestCase

  def test_initialization
    person = Human.new(:name => "David", :age => 50)
    assert_equal("David", person.name)
  end

  def test_save_record
    @person = Human.new
    @person.name = "David"
    @person.age = 50
    assert(@person.save)
  end

  def test_retrieving_object
    test_save_record
    person = Human.find(@person.id)
    assert(person)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def teardown
    FileUtils.rm_rf(Human.dirname) if File.exist?(Human.dirname.to_s)
  end

  def test_initialize_with_hash
    person = Human.new(:name => "David", :age => 50)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def test_attr_mechanics
    assert_equal(%w{ age name },
      Human.instance_variable_get("@attributes").sort)
  end

  def test_new_record
    person = Human.new
    assert(person.new_record?)
  end

  def test_saving_invalid_record
    person = Human.new
    assert(!person.valid?)
    assert_equal(false, person.save)
  end

  def test_updating_attributes
    person = Human.new(:name => "David", :age => 50)
    person.save
    person.update_attributes(:name => "Black", :age => 51)
    assert_equal("Black", person.name)
    assert_equal(51, person.age)

    black = Human.find(person.id)
    assert_equal("Black", person.name)
    assert_equal(51, person.age)
  end

  def test_create
    person = Human.create(:name => "David", :age => 50)
    assert_equal("David", person.name)
    assert_equal(50, person.age)
  end

  def test_next_dbname
    assert_equal(Human.dirname + "/1", Human.next_dbname)
    Human.new(:name => "David", :age => 50).save
    assert_equal(Human.dirname + "/2", Human.next_dbname)
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
