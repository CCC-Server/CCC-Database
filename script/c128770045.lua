local s,id=GetID()
function s.initial_effect(c)
	--덱에서 "매지컬★시스터" 마법/함정 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--②: 싱크로 소환 취급으로 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.sctg)
	e3:SetOperation(s.scop)
	c:RegisterEffect(e3)
end

--① 효과: 덱에서 "매지컬★시스터" 마법/함정 서치
function s.thfilter(c)
	return c:IsSetCard(0x754) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 효과: 싱크로 소환 취급으로 특수 소환
function s.fieldfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsAbleToGrave() and c:IsType(TYPE_MONSTER)
end
function s.deckfilter(c)
	return c:IsSetCard(0x754) and not c:IsType(TYPE_TUNER) and c:IsAbleToGrave() and c:IsType(TYPE_MONSTER)
end
function s.synchrofilter(c,e,tp)
	return c:IsLevel(8) and c:IsSetCard(0x754) and c:IsType(TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.deckfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.synchrofilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	-- 필드의 마법사족 / 빛 속성 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local fieldMonster=Duel.SelectMatchingCard(tp,s.fieldfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not fieldMonster then return end

	-- 덱의 비튜너 "매지컬★시스터" 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local deckMonster=Duel.SelectMatchingCard(tp,s.deckfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if not deckMonster then return end

	-- 두 몬스터를 동시에 묘지로 보냄
	local g=Group.FromCards(fieldMonster,deckMonster)
	if Duel.SendtoGrave(g,REASON_EFFECT)==2 then
		-- 엑스트라 덱에서 싱크로 몬스터 소환
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local synchroMonster=Duel.SelectMatchingCard(tp,s.synchrofilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
		if synchroMonster then
			Duel.SpecialSummon(synchroMonster,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
			synchroMonster:CompleteProcedure()
		end
	end
end
