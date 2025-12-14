local s,id=GetID()
function s.initial_effect(c)
	-- E1: 특수 소환 조건 (묘지에 라바르 몬스터 존재 시)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- E2: 싱크로 소재로 묘지로 보내졌을 때
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)

	-- E3: 묘지에서 싱크로 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+2)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e3:SetCondition(aux.exccon)
	e3:SetTarget(s.sctg)
	e3:SetOperation(s.scop)
	c:RegisterEffect(e3)
end

-- 🔹E1: 특수 소환 조건
function s.spfilter(c)
	return c:IsRace(RACE_PYRO) and c:IsSetCard(0x39)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil)
end

-- 🔹E2: 싱크로 소재로 묘지로 갔을 때
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end
function s.tgfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- 🔹E3: 묘지에서 싱크로 소환
function s.scfilter(c,e,tp,lv)
	return c:IsSetCard(0x39) and c:IsType(TYPE_SYNCHRO)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
		and c:GetLevel()==lv
end
function s.scmatfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToRemove()
end
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.scmatfilter,tp,LOCATION_GRAVE,0,c)
	if chk==0 then
		for lv=1,12 do
			if Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv) and g:CheckWithSumEqual(Card.GetLevel,lv,1,#g) then
				return true
			end
		end
		return false
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.scmatfilter,tp,LOCATION_GRAVE,0,c)
	for lv=1,12 do
		if Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv)
			and g:CheckWithSumEqual(Card.GetLevel,lv,1,#g) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=Duel.SelectMatchingCard(tp,s.scfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv):GetFirst()
			if sc then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local mat=g:SelectWithSumEqual(tp,Card.GetLevel,lv,1,#g)
				if #mat>0 then
					mat:AddCard(c)
					Duel.Remove(mat,POS_FACEUP,REASON_COST)
					sc:SetMaterial(nil)
					Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
					sc:CompleteProcedure()
				end
			end
			return
		end
	end
end
