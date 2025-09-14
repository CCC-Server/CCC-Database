--샐러맨그레이트 클라이맥스 라이오 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,nil,s.lcheck)

	-------------------------------------------------------
	--① 엑덱의 샐러맨 링크 공개 → 이름 복사
	-------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.copytg)
	e1:SetOperation(s.copyop)
	c:RegisterEffect(e1)

	-------------------------------------------------------
	--② "클라이맥스 라이오"를 소재로 링크 소환된 경우 : 상대 효과 무효+덱으로
	-------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-------------------------------------------------------
	--③ 상대 몬스터 소환시 : 이 카드만으로 샐러맨 링크 몬스터 링크 소환
	-------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.lktg)
	e3:SetOperation(s.lkop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end
s.listed_names={id}
s.listed_series={SET_SALAMANGREAT}

-------------------------------------------------------
-- 링크 소재: 화염 속성 효과 몬스터 2장 이상
-------------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE,lc,sumtype,tp) and c:IsType(TYPE_EFFECT,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return #g>=2
end

-------------------------------------------------------
--① 이름 카피 (엑덱에서 공개)
-------------------------------------------------------
function s.namefilter(c)
	return c:IsSetCard(SET_SALAMANGREAT) and c:IsType(TYPE_LINK)
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.namefilter,tp,LOCATION_EXTRA,0,1,nil) end
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.namefilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.ConfirmCards(1-tp,g)
		local code=g:GetFirst():GetCode()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetValue(code)
		c:RegisterEffect(e1)
	end
end

-------------------------------------------------------
--② 무효 & 덱으로
-------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_LINK) and c:GetMaterial():IsExists(Card.IsCode,1,nil,id128101237)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.SendtoDeck(re:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-------------------------------------------------------
--③ 초전생식 링크 소환 (이 카드만 소재)
-------------------------------------------------------
function s.lkfilter(c,e,tp,mc)
	return c:IsSetCard(SET_SALAMANGREAT) and c:IsLinkMonster()
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
		and c:IsCode(mc:GetCode()) -- 자기와 같은 이름으로만
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,e:GetHandler()) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.lkfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
	if sc then
		sc:SetMaterial(Group.FromCards(c))
		Duel.SendtoGrave(c,REASON_EFFECT+REASON_MATERIAL+REASON_LINK)
		Duel.BreakEffect()
		Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
