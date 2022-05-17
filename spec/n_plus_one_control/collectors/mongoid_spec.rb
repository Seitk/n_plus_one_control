# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::Collectors::Mongoid do
  describe "#parse_log" do
    let(:pattern) { "(?i-mx:^SELECT)" }
    let(:name) { "cmd.mongodb" }
    let(:start) { DateTime.now }
    let(:finish) { DateTime.now }
    let(:message_id) { "e0f33dd07421bfdd6f40" }
    subject { described_class.new.parse_log(pattern, name, start, finish, message_id, values) }

    context "with find command" do
      let(:values) { 'MONGODB | [330] 127.0.0.1:27019 #1 | shopline_test.find | STARTED | {"find"=>"invoices", "filter"=>{"order_id"=>BSON::ObjectId(\'62832ef1b679dea3f81d4a4d\')}, "sort"=>{"created_at"=>-1}, "limit"=>1, "singleBatch"=>true, "$db"=>"shopline_test", "lsid"=>{"id"=><BSON::Binary:0x70278866450040 type=uuid data=0x4138b6eded3f4b...' }
      it "parses the log successfully" do
        is_expected.to be_present
        expect(subject.target).to eq("shopline_test.invoices")
        expect(subject.action).to eq("find")
      end

      context "when criteria is long enough to be truncated" do
        let(:values) { 'MONGODB | [249] 127.0.0.1:27019 #1 | shopline_test.find | STARTED | {"find"=>"invoices", "filter"=>{"order_id"=>{"$in"=>[BSON::ObjectId(\'62833079b679deadf5699cfc\'), BSON::ObjectId(\'62833079b679deadf5699d03\'), BSON::ObjectId(\'62833079b679deadf5699d0a\'), BSON::ObjectId(\'62833079b679deadf5699d11\'), BSON::ObjectId(\'628330...' }
        it "parses the log successfully" do
          is_expected.to be_present
          expect(subject.target).to eq("shopline_test.invoices")
          expect(subject.action).to eq("find")
        end
      end
    end
  end
end
