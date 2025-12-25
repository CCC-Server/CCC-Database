--블랙 어썰트 어라이징
--Black Assault Arising
local s,id=GetID()
local CARD_BLACK_WINGED_ASSAULT_DRAGON=73218989
function s.initial_effect(c)
	--① 발동 효과 : BF 싱크로나 블랙 페더 드래곤이 있을 때
	--싱크로 몬스터 1장 + 필드 카드 1장을 묘지로 보내고
	--엑스트라에서 "블랙 페더 어썰트 드래곤"을 싱크로 소환 취급으로 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--② 묘지에서 : 자신 필드의 어둠 속성 싱크로가 효과로 파괴될 경우 대신 제외
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_BLACKWING}
s.listed_names={CARD_BLACK_WINGED_DRAGON,CARD_BLACK_WINGED_ASSAULT_DRAGON}

--------------------------------
-- ① 효과 처리
--------------------------------

-- 발동 조건: 필드에 "BF" 싱크로 또는 "블랙 페더 드래곤"이 존재해야 함
function s.confilter(c)
	return c:IsFaceup() and ((c:IsSetCard(SET_BLACKWING) and c:IsType(TYPE_SYNCHRO)) or c:IsCode(CARD_BLACK_WINGED_DRAGON))
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 묘지로 보낼 싱크로 몬스터 필터
function s.synfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsAbleToGrave()
end
-- 묘지로 보낼 다른 카드 필터 (sc는 위에서 선택한 싱크로 몬스터)
function s.fieldtgfilter(c,sc)
	return c:IsAbleToGrave() and c~=sc
end
-- 특수 소환할 몬스터 필터 (란세아 로직 참조)
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_BLACK_WINGED_ASSAULT_DRAGON)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 -- 이 카드를 소환할 공간이 있는지 구체적으로 확인
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 발동 시점에는 아직 묘지로 보내지 않았으므로 공간이 꽉 차 있으면 발동 불가한 것이 기본 룰입니다.
		-- 만약 묘지로 보내는 행위로 공간이 비는 것을 허용하려면 GetLocationCountFromEx 체크를 생략해야 하지만,
		-- 일반적으로는 현재 상태에서 소환 가능성을 체크합니다.
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,2,nil) -- 최소 2장 존재 확인
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,4,tp,0x10) -- 0x10: 검은 날개 카운터
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 싱크로 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local sc=g1:GetFirst()
	if not sc then return end

	-- 2. 필드의 다른 카드 1장 선택 (sc 제외)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.fieldtgfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,sc)
	if #g2==0 then return end
	
	g1:Merge(g2)
	
	-- 3. 묘지로 보내고, 성공적으로 2장이 보내졌다면 특수 소환 진행
	if Duel.SendtoGrave(g1,REASON_EFFECT)==2 then
		-- 묘지로 보낸 후 소환 가능한지 다시 체크 (공간이 생겼을 수 있음)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		local tc=sg:GetFirst()
		
		if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
			-- 정규 소환 취급 (소생 제한 룰 만족)
			tc:CompleteProcedure()
			-- 검은 날개 카운터 4개
			if tc:IsCanAddCounter(0x10,4) then
				tc:AddCounter(0x10,4)
			end
		end
	end
end

--------------------------------
-- ② 효과 처리
--------------------------------

function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsOnField() and c:IsFaceup()
		and c:IsAttribute(ATTRIBUTE_DARK) and c:IsType(TYPE_SYNCHRO)
		and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp)
	end
	if Duel.SelectEffectYesNo(tp,c,96) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
		local g=eg:Filter(s.repfilter,nil,tp)
		local tg=g:Select(tp,1,1,nil)
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
	local g=e:GetLabelObject()
	if g then g:DeleteGroup() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end