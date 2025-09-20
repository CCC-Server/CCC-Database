--샐러맨그레이트 클라이맥스 라이오 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-- 링크 소환
	c:EnableReviveLimit()
	-- 화염 속성 효과 몬스터 2장
	Link.AddProcedure(c,s.matfilter,2,2)
	-- 재전생 링크 체크(자기 이름을 소재로 링크 소환되었는지 플래그 처리)
	aux.EnableCheckReincarnation(c)

	-------------------------------------------------------
	-- ① 엑덱의 샐러맨 링크 공개 → 이름 복사 (턴 1)
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
	-- ② "이 카드가 재전생 링크 소환되었을 때" 퍼미션: 상대 효과 무효 + 그 카드 덱으로
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
	-- ③ 상대가 몬스터를 소환했을 때: 이 카드만을 소재로
	--    자기와 같은 이름의 "샐러맨그레이트" 링크 몬스터 링크 소환
	-------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.lkcon)
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
-- 링크 소재: 화염 속성 효과 몬스터
-------------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE,lc,sumtype,tp) and c:IsType(TYPE_EFFECT,lc,sumtype,tp)
end

-------------------------------------------------------
-- ① 엑덱 공개 → 이름 복사
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
-- ② 재전생 링크 소환되었을 때만 발동되는 퍼미션
--    (상대 효과 체인 무효 + 그 카드 덱으로 되돌림)
-------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp==1-tp and Duel.IsChainNegatable(ev)
		and c:IsLinkSummoned() and c:IsReincarnationSummoned()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.SendtoDeck(re:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-------------------------------------------------------
-- ③ 상대 소환 트리거 → 이 카드 1장만 소재, 같은 이름의 샐러맨 링크를 링크 소환
-------------------------------------------------------
local function opp_summoned(eg,tp)
	return eg:IsExists(function(c,pt) return c:IsControler(1-pt) end,1,nil,tp)
end
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return opp_summoned(eg,tp)
end
function s.lkfilter(c,mc)
	-- 같은 이름, 샐러맨그레이트 링크, "이 카드 1장만"으로 링크 소환 가능
	return c:IsSetCard(SET_SALAMANGREAT) and c:IsLinkMonster()
		and c:IsCode(mc:GetCode())
		and c:IsLinkSummonable(mc) -- mc 단독으로 링크 소환 가능한지(엔진 판단)
end
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and c:IsFaceup()) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,function(x) return s.lkfilter(x,c) end,tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()
	if sc then
		-- 이 카드 1장만 소재로 링크 소환 강제
		Duel.LinkSummon(tp,sc,c)
	end
end
