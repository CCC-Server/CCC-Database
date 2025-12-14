--Dual Dragon Fusion Emperor (듀얼 드래곤 퓨전 엠퍼러)
local s,id=GetID()
function s.initial_effect(c)
	--소재 지정
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)

	-----------------------------------------------------
	--① 상대가 필드 이외에서 카드의 효과를 발동했을 때 무효+파괴
	-----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-----------------------------------------------------
	--② 융합 소환 + 발동 횟수에 따라 강화 효과
	-----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_FUSION_SUMMON+CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(3,{id,1}) -- 1턴에 3번까지 발동 가능
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------
--소재 필터: 드래곤족 듀얼 몬스터
-----------------------------------------------------
function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_GEMINI,fc,sumtype,tp)
end

-----------------------------------------------------
--① 무효 + 파괴
-----------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return loc~=LOCATION_ONFIELD
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end

-----------------------------------------------------
--② 융합 소환 + 강화 효과
-----------------------------------------------------
function s.fusfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
end
function s.dragon_fusfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end
function s.fusfilter_extra(c,mg,e,tp)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,nil)
		return Duel.IsExistingMatchingCard(s.fusfilter_extra,tp,LOCATION_EXTRA,0,1,nil,mg,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local fus=Duel.SelectMatchingCard(tp,s.fusfilter_extra,tp,LOCATION_EXTRA,0,1,1,nil,mg,e,tp):GetFirst()
	if not fus then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local mat=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,0,2,99,nil)
	if #mat==0 or not mat:IsExists(s.dragon_fusfilter,1,nil) then return end -- 반드시 드래곤족 듀얼 포함
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.BreakEffect()
	if Duel.SpecialSummon(fus,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		fus:CompleteProcedure()
	end

	--발동 횟수 추적 및 강화 적용
	local c=e:GetHandler()
	local ct=c:GetFlagEffect(id)
	c:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1,ct+1)
	s.apply_bonus(e,tp,ct+1)
end

-----------------------------------------------------
--강화 효과 적용 (횟수별)
-----------------------------------------------------
function s.apply_bonus(e,tp,ct)
	local g=Duel.GetMatchingGroup(function(c)
		return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
	end,tp,LOCATION_MZONE,0,nil)

	if ct==1 then
		for tc in g:Iter() do
			tc:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
		end
		Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,2))
	elseif ct==2 then
		for tc in g:Iter() do
			tc:RegisterFlagEffect(id,RESET_PHASE+PHASE_DRAW,0,1)
		end
		Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,3))
	elseif ct>=3 then
		for tc in g:Iter() do
			tc:RegisterFlagEffect(id,0,0,1)
		end
		Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,4))
	end
end
