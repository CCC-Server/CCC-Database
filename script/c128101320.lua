--블랙 어썰트 어라이징
--Black Assault Arising
local s,id=GetID()
local CARD_BLACK_WINGED_ASSAULT_DRAGON=73218989
function s.initial_effect(c)
	--① 발동 효과 : BF 싱크로나 블랙 페더 드래곤이 있을 때
	--싱크로 몬스터 1장 + 필드 카드 1장을 묘지로 보내고
	--엑스트라에서 "블랙 페더 어썰트 드래곤"을 싱크로 소환 취급으로 특수 소환,
	--그 후 그 몬스터에 검은 날개 카운터 4개를 놓는다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) --① 1턴 1번
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--② 묘지에서 : 자신 필드의 어둠 속성 싱크로가 효과로 파괴될 경우,
	--대신에 이 카드를 제외할 수 있다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) --② 1턴 1번
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_BLACKWING}
s.listed_names={CARD_BLACK_WINGED_DRAGON,CARD_BLACK_WINGED_ASSAULT_DRAGON}
s.counter_list={COUNTER_FEATHER}

--------------------------------
-- ① 효과 : 어썰트 드래곤 특소 + 카운터 4개
--------------------------------

-- BF 싱크로 또는 블랙 페더 드래곤 존재 여부
function s.confilter(c)
	return c:IsFaceup()
		and ((c:IsSetCard(SET_BLACKWING) and c:IsType(TYPE_SYNCHRO)) or c:IsCode(CARD_BLACK_WINGED_DRAGON))
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.synfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsAbleToGrave()
end
function s.fieldtgfilter(c,sc)
	-- 필드의 카드 1장 (싱크로와는 다른 카드여야 함)
	return c:IsAbleToGrave() and c~=sc
end
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_BLACK_WINGED_ASSAULT_DRAGON)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 싱크로 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local sc=g1:GetFirst()
	if not sc then return end
	-- 필드의 다른 카드 1장 선택 (상대 필드 가능)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,function(tc) return s.fieldtgfilter(tc,sc) end,
		tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g2==0 then return end
	g1:Merge(g2)
	if Duel.SendtoGrave(g1,REASON_EFFECT)~=2 then return end

	-- 어썰트 드래곤 특수 소환 (싱크로 소환 취급)
	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
		-- 검은 날개 카운터 4개
		if tc:IsCanAddCounter(COUNTER_FEATHER,4) then
			tc:AddCounter(COUNTER_FEATHER,4)
		end
	end
end

--------------------------------
-- ② 효과 : 파괴 대체
--------------------------------

function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsOnField() and c:IsFaceup()
		and c:IsAttribute(ATTRIBUTE_DARK) and c:IsType(TYPE_SYNCHRO)
		and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemove()
			and eg:IsExists(s.repfilter,1,nil,tp)
	end
	-- 보호할 몬스터 1장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
	local g=eg:Filter(s.repfilter,nil,tp)
	local tg=g:Select(tp,1,1,nil)
	if #tg>0 then
		tg:KeepAlive()
		e:SetLabelObject(tg)
		return true
	else
		return false
	end
end
function s.repval(e,c)
	local g=e:GetLabelObject()
	return g and g:IsContains(c)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=e:GetLabelObject()
	if g then g:DeleteGroup() end
	if c:IsRelateToEffect(e) then
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	end
end
