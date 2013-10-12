#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
require 'open-uri'

class Tr8n::Emails::Asset < ActiveRecord::Base
  self.table_name = :tr8n_email_assets

  attr_accessible :path, :keyword, :application

  belongs_to :application, :class_name => 'Tr8n::Application'

  serialize :thumbnails

  after_create :finalize_creation
  before_destroy :finalize_deletion

  def self.paths_for(name)
    file_name = generate_file_name(name)
    relative_path = "media/#{generate_folder_name}"
    full_path = Tr8n::Config.root.join('public', relative_path)
    FileUtils.mkdir_p(full_path)
    relative_path += "/#{file_name}"
    full_path = full_path.join(file_name)
    [relative_path, full_path]
  end

  def self.create_from_file(application, name, data)
    relative_path, full_path = paths_for(name)

    File.open(full_path, 'wb') do |file|
      file.write(data)
    end

    create(:application => application, :path => relative_path, :keyword => name)
  end

  def self.create_from_url(application, url)
    relative_path, full_path = paths_for(url)

    File.open(full_path, 'wb') do |file|
      file.write(open(url).read)
    end

    create(:application => application, :path => relative_path, :keyword => name)
  end

  def url(size = :original, opts = {})
    return "#{Tr8n::Config.media_url}/#{file_path(size)}" if opts[:full]
    "/#{file_path(size)}"
  end

  def full_path(size = :original)
    Rails.root.join('public', file_path(size)).to_s
  end

  def magick
    @magick ||= begin
      img = Magick::Image.read(full_path).first
      img = img.first if img.is_a?(Array)
      img
    end
  end

  def create_thumbnails
    SIZES.each do |name, opts|
      if opts[:method] == :fit
        thumb = magick.resize_to_fit(opts[:width], opts[:height])
      elsif opts[:method] == :fill
        thumb = magick.resize_to_fill(opts[:width], opts[:height])
      end
      # pp "Creating thumb file: #{full_path(name)}..."
      thumb.write(full_path(name))
      thumb.destroy!
    end
  end

  def file_path(size = :original)
    return path if size == :original
    dirs = path.split("/")
    "#{dirs[0..-2].join('/')}/#{file_name(size)}"
  end

  def file_name(size = :original)
    name = path.split("/").last
    return name if size == :original

    ext = name.split(".").last
    name_only = name[0..-(ext.size+2)]
    "#{name_only}-#{size}.#{ext}"
  end

  def file_ext
    path.split(".").last
  end

  def delete_files
    if File.exists?(full_path)
      File.delete(full_path)
    end

    #SIZES.each do |name, opts|
    #  next unless File.exists?(full_path(name))
    #  File.delete(full_path(name))
    #end
  rescue Exception => ex
    pp "Failed to delete file: #{ex.message}"
  end

  private

  def finalize_creation
    # create_thumbnails
    # magick.destroy! if magick
  end

  def finalize_deletion
    delete_files
  end

  def self.generate_file_name(name)
    ext = name.split('.').last.downcase
    ext = 'png' unless ['jpg', 'jpeg', 'gif', 'png'].include?(ext)
    "#{Tr8n::Utils.guid}.#{ext}"
  end

  def self.generate_folder_name
    fpath = []
    4.times do
      fpath << rand(100)
    end
    fpath.join("/")
  end

end
