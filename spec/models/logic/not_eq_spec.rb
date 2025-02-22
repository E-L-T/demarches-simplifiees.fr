describe Logic::NotEq do
  include Logic

  describe '#compute' do
    it { expect(ds_not_eq(constant(1), constant(1)).compute).to be(false) }
    it { expect(ds_not_eq(constant(1), constant(2)).compute).to be(true) }
  end

  describe '#errors' do
    it { expect(ds_not_eq(constant(true), constant(true)).errors).to be_empty }
    it { expect(ds_not_eq(constant(true), constant(1)).errors).to eq(["les types sont incompatibles : (Oui != 1)"]) }
  end

  describe '#==' do
    it { expect(ds_not_eq(constant(true), constant(false))).to eq(ds_not_eq(constant(false), constant(true))) }
  end
end
