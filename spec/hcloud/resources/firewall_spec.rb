# frozen_string_literal: true

RSpec.describe HCloud::Firewall, :integration, order: :defined do
  firewall_server, firewall_label = nil

  server = nil
  server2 = nil

  it "creates a firewall applied to a label" do
    server = HCloud::Server.create(name: "first", image: IntegrationDefaults.image, server_type: IntegrationDefaults.server_type, labels: { environment: "production" })
    server2 = HCloud::Server.create(name: "second", image: IntegrationDefaults.image, server_type: IntegrationDefaults.server_type, labels: { environment: "staging" })

    wait_for { server.reload.status }.to eq("running")
    wait_for { server2.reload.status }.to eq("running")

    firewall = described_class.create(name: "firewall_applied_to_a_label", apply_to: [{ type: "label_selector", label_selector: { selector: "environment=production" } }])
    firewall.reload

    expect(firewall).to be_created
    expect(firewall.id).not_to be_nil

    expect(firewall.applied_to.first.type).to eq "label_selector"
    expect(firewall.applied_to.first.label_selector).to eq selector: "environment=production"

    firewall_label = firewall.id
  end

  it "creates a firewall applied to a server" do
    firewall = described_class.create(name: "firewall_applied_to_a_server", apply_to: [{ type: "server", server: server2 }])

    firewall.reload

    expect(firewall).to be_created
    expect(firewall.id).not_to be_nil

    expect(firewall.applied_to.first.type).to eq "server"
    expect(firewall.applied_to.first.server).to eq server2

    firewall_server = firewall.id
  end

  it "finds an firewall" do
    firewall = described_class.find(firewall_server)

    expect(firewall.name).to eq "firewall_applied_to_a_server"
  end

  it "lists firewalls" do
    firewalls = described_class.all

    expect(firewalls.count).to eq 2
    expect(firewalls.map(&:id)).to contain_exactly(firewall_server, firewall_label)
  end

  it "sorts firewalls" do
    list_desc = described_class.all.sort(name: :desc).map(&:name)
    list_asc = described_class.all.sort(name: :asc).map(&:name)
    expect(list_desc.count).to eq 2
    expect(list_asc.count).to eq 2
    expect(list_desc).to eq list_asc.reverse
  end

  it "filters firewalls" do
    firewalls = described_class.all.where(name: "firewall_applied_to_a_label")

    expect(firewalls.count).to eq 1
    expect(firewalls.first.id).to eq firewall_label
  end

  it "updates a firewall" do
    firewall = described_class.find(firewall_server)

    firewall.name = "other_firewall"

    firewall.update

    firewall = described_class.find(firewall_server)

    expect(firewall.name).to eq "other_firewall"
  end

  it "deletes a firewall" do
    server.delete

    firewall = described_class.find(firewall_server)

    firewall.delete

    expect(firewall).to be_deleted

    expect { described_class.find(firewall_server) }.to raise_error HCloud::Errors::NotFound
  end
end
