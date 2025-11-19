--하피 링크 몬스터 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon: 2+ "Harpie" monsters
	Link.AddProcedure(c,s.matfilter,2,99)
	c:EnableReviveLimit()

	-- ① Name becomes "Harpie Lady Sisters" on field/grave
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e1:SetValue(CARD_HARPIE_LADY_SISTERS)
	c:RegisterEffect(e1)

	-- ② Quick Effect: Add 1 Hysteric S/T from Deck/GY to hand, optionally discard 1, then double ATK
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Set name codes
s.listed_names={CARD_HARPIE_LADY_SISTERS,19337371,21297224,77778835}
s.listed_series={SET_HARPIE}

-- 소재: "하피" 몬스터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_HARPIE,lc,sumtype,tp)
end

-- 히스테릭 카드 ID 목록
local hysteric_ids = {
	19337371, -- Hysteric Sign
	21297224, -- Hysteric Fairy
	77778835  -- Hysteric Party
}

function s.isHysteric(c)
	for _,code in ipairs(hysteric_ids) do
		if c:IsCode(code) then return true end
	end
	return false
end

-- 덱/묘지에서 히스테릭 카드 서치
function s.thfilter(c)
	return c:IsSpellTrap() and c:IsAbleToHand() and s.isHysteric(c)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		-- Optional: send 1 card from hand to GY
		if Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		end
		-- Double ATK
		if c:IsFaceup() and c:IsRelateToEffect(e) then
			local atk=c:GetAttack()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(atk*2)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
	end
end
