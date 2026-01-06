# frozen_string_literal: true

module IntegrationDefaults
  def self.image
    @image ||= HCloud::Image.where(type: "system", name: "ubuntu-24.04", architecture: "arm").first
  end

  def self.server_type
    "cax11"
  end
end
