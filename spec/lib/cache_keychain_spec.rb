require 'pebblebed'
require 'cache_key'
require 'cache_keychain'

describe CacheKeychain do
  let(:doc) { 'post.doc:a.b.c$1337' }
  let(:haste) { 'post.haste:x.y.z$120' }
  let(:card) { 'post.card:p.r.q$66' }

  let(:doc_key) { 'post.doc:*$1337' }
  let(:haste_key) { 'post.haste:*$120' }
  let(:card_key) { 'post.card:*$66' }

  subject { CacheKeychain.new [doc, haste, card] }

  it "resolves uids" do
    subject.keys.should eq([doc_key, haste_key, card_key])
  end

  it "marks a key" do
    subject.mark 'post.doc:*$1337'
    subject.unmarked.should eq(haste_key => haste, card_key => card)
  end

  it "marks keys" do
    subject.mark ['post.doc:*$1337', 'post.haste:*$120']
    subject.unmarked.should eq(card_key => card)
  end

end