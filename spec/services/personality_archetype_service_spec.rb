require 'rails_helper'

RSpec.describe PersonalityArchetypeService do
  describe '.get_archetype' do
    context 'with valid type codes' do
      it 'returns the correct archetype for AGEA' do
        archetype = described_class.get_archetype('AGEA')
        expect(archetype[:title]).to eq('The Visionary Explorer')
        expect(archetype[:description]).to include('drawn to films that push the boundaries')
      end

      it 'returns the correct archetype for AGEI' do
        archetype = described_class.get_archetype('AGEI')
        expect(archetype[:title]).to eq('The Philosophical Dreamer')
        expect(archetype[:description]).to include('gateway to deeper understanding')
      end

      it 'returns the correct archetype for AGER' do
        archetype = described_class.get_archetype('AGER')
        expect(archetype[:title]).to eq('The Artistic Realist')
        expect(archetype[:description]).to include('beauty in the raw authenticity')
      end

      it 'returns the correct archetype for AGIR' do
        archetype = described_class.get_archetype('AGIR')
        expect(archetype[:title]).to eq('The Contemplative Observer')
        expect(archetype[:description]).to include('both introspective and analytical')
      end

      it 'returns the correct archetype for AGIA' do
        archetype = described_class.get_archetype('AGIA')
        expect(archetype[:title]).to eq('The Aesthetic Adventurer')
        expect(archetype[:description]).to include('journey through visual poetry')
      end

      it 'returns the correct archetype for RGEA' do
        archetype = described_class.get_archetype('RGEA')
        expect(archetype[:title]).to eq('The Emotional Voyager')
        expect(archetype[:description]).to include('navigate the world of cinema through your heart')
      end

      it 'returns the correct archetype for RGEI' do
        archetype = described_class.get_archetype('RGEI')
        expect(archetype[:title]).to eq('The Empathetic Analyst')
        expect(archetype[:description]).to include('balances emotional resonance with intellectual curiosity')
      end

      it 'returns the correct archetype for RGER' do
        archetype = described_class.get_archetype('RGER')
        expect(archetype[:title]).to eq('The Authentic Storyteller')
        expect(archetype[:description]).to include('value cinema that speaks to the heart')
      end

      it 'returns a hash with title and description for each archetype' do
        described_class::ARCHETYPES.each do |type_code, archetype|
          expect(archetype).to have_key(:title)
          expect(archetype).to have_key(:description)
          expect(archetype[:title]).to be_a(String)
          expect(archetype[:description]).to be_a(String)
          expect(archetype[:title]).not_to be_empty
          expect(archetype[:description]).not_to be_empty
        end
      end
    end

    context 'with invalid type codes' do
      it 'returns the default archetype for nil type code' do
        archetype = described_class.get_archetype(nil)
        expect(archetype[:title]).to eq('The Cinematic Explorer')
        expect(archetype[:description]).to include('unique approach to cinema')
      end

      it 'returns the default archetype for unknown type code' do
        archetype = described_class.get_archetype('XXXX')
        expect(archetype[:title]).to eq('The Cinematic Explorer')
        expect(archetype[:description]).to include('unique approach to cinema')
      end

      it 'returns the default archetype for empty string' do
        archetype = described_class.get_archetype('')
        expect(archetype[:title]).to eq('The Cinematic Explorer')
        expect(archetype[:description]).to include('unique approach to cinema')
      end
    end

    context 'archetype structure' do
      it 'has consistent structure across all archetypes' do
        all_archetypes = described_class::ARCHETYPES.values + [described_class.get_archetype('INVALID')]
        
        all_archetypes.each do |archetype|
          expect(archetype).to match(
            title: be_a(String),
            description: be_a(String)
          )
        end
      end
    end
  end
end
