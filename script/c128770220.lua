local s,id=GetID()
function s.initial_effect(c)
	--① 레벨 변경
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.lvop)
	c:RegisterEffect(e1)

	--② 릴리스 후 묘지의 "스파클 아르카디아" 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--③ 싱크로 소재로 묘지로 보냈을 경우
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thspcon)
	e3:SetTarget(s.thsptg)
	e3:SetOperation(s.thspop)
	c:RegisterEffect(e3)

	--④ 싱크로 소재 제한 ("스파클 아르카디아" 싱크로만 가능)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e4:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e4:SetValue(s.synlimit)
	c:RegisterEffect(e4)
end

----------------------------------------
--①: 레벨 변경
----------------------------------------
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() or not c:IsRelateToEffect(e) then return end
	local lv=Duel.AnnounceLevel(tp,1,8)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LEVEL_FINAL)
	e1:SetValue(lv)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

----------------------------------------
--②: 릴리스 비용 + 묘지 특수 소환
----------------------------------------
function s.costfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x760)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.costfilter,1,false,nil,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,s.costfilter,1,1,false,nil,nil)
	Duel.Release(g,REASON_COST)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x760) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------
--③: 싱크로 소재로 묘지로 갔을 때
----------------------------------------
function s.thspcon(e,tp,eg,ep,ev,re,r,rp)
	return r&REASON_SYNCHRO~=0
end
function s.tgfilter(c)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsAbleToGrave()
end
function s.handspfilter(c,e,tp)
	return c:IsSetCard(0x760) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.thsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local b1=Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
		local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and
			Duel.IsExistingMatchingCard(s.handspfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
		return b1 or b2
	end
end
function s.thspop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and
		Duel.IsExistingMatchingCard(s.handspfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else return end

	if op==0 then
		-- 덱에서 "스파클 아르카디아" 몬스터 1장을 묘지로 보낸다
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
	else
		-- 패의 "스파클 아르카디아" 몬스터 1장을 특수 소환한다
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.handspfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) end
	end
end

----------------------------------------
--④: 싱크로 소재 제한 ("스파클 아르카디아" 싱크로만 가능)
----------------------------------------
function s.synlimit(e,c)
	if not c then return false end
	return not c:IsSetCard(0x760)
end
